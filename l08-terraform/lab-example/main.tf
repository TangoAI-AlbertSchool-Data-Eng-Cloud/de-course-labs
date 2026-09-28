# ---------------------------------------------------------------------------
# main.tf - GENERATED, DO NOT EDIT HERE.
#
# The public copy of the lab that creates your group's Google Cloud project.
# It is generated from the private staff repository by scripts/build-lab-example.mjs
# in the course platform, and the values it needs - the billing account, the
# parent folder, your addresses - live in a terraform.tfvars that is never
# published. See terraform.tfvars.example for their shape.
#
# You are not meant to run this. You are meant to read it: it is the
# infrastructure you have been working inside since lesson 2, written down.
# ---------------------------------------------------------------------------

// ---------------------------------------------------------------------------
// One GCP project per student group, for MSA-DAT09-02.
//
// Bible D21: staff create these before L02. Students never create a project or
// a billing link; from L02 they sign in to one that exists.
// ---------------------------------------------------------------------------

locals {
  // Project IDs are globally unique, 6-30 characters, lowercase.
  // albert-de + msc2-26 + g01 = "albert-de-msc2-26-g01", 21 characters.
  project_ids = {
    for g, _ in var.groups : g => "${var.project_prefix}-${var.cohort}-${g}"
  }

  // Flattened (group, member) pairs, so one IAM binding per member per role.
  group_members = flatten([
    for g, members in var.groups : [
      for m in members : { group = g, member = m }
    ]
  ])

  roles = concat(
    var.student_roles,
    var.enable_project_iam_admin ? ["roles/resourcemanager.projectIamAdmin"] : [],
  )

  bindings = {
    for pair in flatten([
      for gm in local.group_members : [
        for r in local.roles : {
          key    = "${gm.group}/${r}/${gm.member}"
          group  = gm.group
          role   = r
          member = gm.member
        }
      ]
    ]) : pair.key => pair
  }
}

// Fail early and loudly rather than halfway through creating projects.
resource "terraform_data" "preconditions" {
  lifecycle {
    precondition {
      condition     = (var.org_id == null) != (var.folder_id == null)
      error_message = "Set exactly one of org_id or folder_id."
    }

    precondition {
      condition     = alltrue([for id in values(local.project_ids) : length(id) <= 30])
      error_message = "A generated project ID exceeds 30 characters. Shorten project_prefix or cohort."
    }

    precondition {
      condition     = alltrue([for id in values(local.project_ids) : can(regex("^[a-z][a-z0-9-]{4,28}[a-z0-9]$", id))])
      error_message = "A generated project ID is not a valid one: lowercase letters, digits and hyphens, starting with a letter."
    }
  }
}

// ---------------------------------------------------------------------------
// The projects
// ---------------------------------------------------------------------------

resource "google_project" "group" {
  for_each = var.groups

  name       = "Albert-DE-${upper(each.key)}-${var.cohort}"
  project_id = local.project_ids[each.key]

  org_id    = var.org_id
  folder_id = var.folder_id

  billing_account     = var.billing_account
  auto_create_network = var.auto_create_network
  deletion_policy     = var.deletion_policy

  // L09 reads costs broken down by these. GCP labels, not tags: labels are
  // what appears in the billing export (bible section 15.2, L09 fix).
  labels = {
    course = "msa-dat09-02"
    cohort = var.cohort
    group  = each.key
    owner  = "staff"
  }

  depends_on = [terraform_data.preconditions]
}

// ---------------------------------------------------------------------------
// APIs
//
// disable_on_destroy = false: disabling an API on teardown can fail when a
// resource still uses it, which would block `terraform destroy` on the last
// day of the course. Deleting the project removes the APIs with it.
// ---------------------------------------------------------------------------

resource "google_project_service" "api" {
  for_each = {
    for pair in setproduct(keys(var.groups), var.apis) :
    "${pair[0]}/${pair[1]}" => { group = pair[0], service = pair[1] }
  }

  project = google_project.group[each.value.group].project_id
  service = each.value.service

  disable_on_destroy         = false
  disable_dependent_services = false
}

// ---------------------------------------------------------------------------
// Who can do what
//
// One binding per (member, role) rather than google_project_iam_binding, which
// is authoritative for a role and would silently remove anyone it does not
// list - including the staff account.
// ---------------------------------------------------------------------------

resource "google_project_iam_member" "student" {
  for_each = local.bindings

  project = google_project.group[each.value.group].project_id
  role    = each.value.role
  member  = "user:${each.value.member}"

  depends_on = [google_project_service.api]
}

// ---------------------------------------------------------------------------
// Budgets
//
// A budget ALERTS, it does not cap. Nothing here stops a group spending past
// it; see docs/runbook.md for what to do about that.
// ---------------------------------------------------------------------------

resource "google_billing_budget" "group" {
  for_each = var.groups

  billing_account = var.billing_account
  display_name    = "Albert DE ${upper(each.key)} (${var.cohort})"

  budget_filter {
    projects = ["projects/${google_project.group[each.key].number}"]
  }

  amount {
    specified_amount {
      currency_code = var.budget_currency
      units         = tostring(var.budget_amount)
    }
  }

  dynamic "threshold_rules" {
    for_each = var.budget_thresholds
    content {
      threshold_percent = threshold_rules.value
    }
  }
}
