# ---------------------------------------------------------------------------
# variables.tf - GENERATED, DO NOT EDIT HERE.
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
// What the school must supply. None of these have defaults on purpose: a wrong
// billing account or parent creates projects in the wrong place, and that is
// not cheap to undo.
// ---------------------------------------------------------------------------

variable "billing_account" {
  description = "Billing account ID to attach every group project to, e.g. 0X0X0X-0X0X0X-0X0X0X. From the school."
  type        = string

  validation {
    condition     = can(regex("^[0-9A-F]{6}-[0-9A-F]{6}-[0-9A-F]{6}$", var.billing_account))
    error_message = "A billing account ID looks like 0X0X0X-0X0X0X-0X0X0X (uppercase hex, three groups of six)."
  }
}

variable "org_id" {
  description = "Numeric organisation ID the projects are created under. Set this OR folder_id, not both."
  type        = string
  default     = null
}

variable "folder_id" {
  description = "Numeric folder ID the projects are created under. Set this OR org_id, not both. A folder is the tidier option: it can be deleted at the end of the course."
  type        = string
  default     = null
}

// ---------------------------------------------------------------------------
// The cohort and its groups.
// ---------------------------------------------------------------------------

variable "cohort" {
  description = "Short cohort tag, used in project IDs and labels. Lowercase letters and digits, e.g. msc2-26."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]{2,10}$", var.cohort))
    error_message = "Use 2 to 10 lowercase letters, digits or hyphens: it becomes part of a project ID."
  }
}

variable "groups" {
  description = <<-EOT
    One entry per student group: a short key, and the Google accounts of its
    members. The key becomes part of the project ID, so keep it to g01, g02, ...

    Members are the addresses students sign in to Google with. A typo here
    means a student who cannot reach their project on the morning of L02, so
    the list is checked by scripts/check-lab.sh before the session.

    Example:
      groups = {
        g01 = ["ada@example.org", "grace@example.org", "alan@example.org"]
        g02 = ["edsger@example.org", "barbara@example.org"]
      }
  EOT
  type        = map(list(string))

  validation {
    condition     = alltrue([for k in keys(var.groups) : can(regex("^[a-z][a-z0-9]{1,5}$", k))])
    error_message = "Group keys must be 2-6 characters, starting with a letter, e.g. g01."
  }

  validation {
    condition     = alltrue(flatten([for k, m in var.groups : [for e in m : can(regex("^[^@ ]+@[^@ ]+\\.[^@ ]+$", e))]]))
    error_message = "Every member must be an email address."
  }
}

// ---------------------------------------------------------------------------
// Shape of each project. The defaults are the course's decisions; change them
// in the bible first, not here.
// ---------------------------------------------------------------------------

variable "project_prefix" {
  description = "Prefix for generated project IDs. Project IDs are globally unique and capped at 30 characters, so keep it short."
  type        = string
  default     = "albert-de"
}

variable "region" {
  description = "Region for everything the students create. Bible D10: europe-west1."
  type        = string
  default     = "europe-west1"
}

variable "budget_amount" {
  description = "Budget per group, in budget_currency. From the school. The budget only alerts; it does not cap spending (see docs/runbook.md)."
  type        = number
}

variable "budget_currency" {
  description = "Currency of budget_amount. Must match the billing account's currency, or the budget is rejected."
  type        = string
  default     = "EUR"
}

variable "budget_thresholds" {
  description = "Fractions of the budget at which an alert fires."
  type        = list(number)
  default     = [0.5, 0.9, 1.0]
}

variable "apis" {
  description = "APIs enabled on every group project, in the order the course needs them."
  type        = list(string)
  default = [
    "cloudresourcemanager.googleapis.com", // L02: the project itself
    "serviceusage.googleapis.com",
    "iam.googleapis.com",              // L02: service accounts
    "storage.googleapis.com",          // L02: buckets
    "bigquery.googleapis.com",         // L02: external tables, L04: warehouse
    "bigquerystorage.googleapis.com",  // L04: fast reads
    "artifactregistry.googleapis.com", // L06: images
    "run.googleapis.com",              // L06: jobs
    "logging.googleapis.com",          // L09, L10
    "monitoring.googleapis.com",       // L09
    "cloudbilling.googleapis.com",     // L09: costs
  ]
}

variable "student_roles" {
  description = <<-EOT
    Project roles granted to every member of a group.

    This list is deliberately NOT roles/editor. L02 teaches least privilege and
    L10 audits it, so the lab cannot hand out a role the course calls a mistake.
    Each entry below exists because a specific lesson needs it.

    Notably absent, and on purpose:
      - roles/iam.serviceAccountKeyAdmin - downloadable keys are the credential
        students would then commit to a public repo. They impersonate instead,
        with roles/iam.serviceAccountTokenCreator below.
      - roles/resourcemanager.projectIamAdmin - it would let a student grant
        themselves owner. See enable_project_iam_admin if L08 turns out to
        need it.
  EOT
  type        = list(string)
  default = [
    "roles/storage.admin",                  // L02: buckets, lifecycle, bucket IAM
    "roles/bigquery.admin",                 // L02, L04, L05
    "roles/iam.serviceAccountAdmin",        // L02: create the ML team's account
    "roles/iam.serviceAccountUser",         // L02, L06: attach it
    "roles/iam.serviceAccountTokenCreator", // L02: prove it cannot write, without keys
    "roles/artifactregistry.admin",         // L06
    "roles/run.admin",                      // L06
    "roles/logging.viewer",                 // L09, L10
    "roles/monitoring.viewer",              // L09
    "roles/serviceusage.serviceUsageConsumer",
  ]
}

variable "enable_project_iam_admin" {
  description = "Also grant roles/resourcemanager.projectIamAdmin. Leave false unless L08's Terraform exercise proves it necessary: it lets a student grant themselves any role, including owner."
  type        = bool
  default     = false
}

variable "auto_create_network" {
  description = "Create the default VPC in each project. False keeps the projects clean; nothing the course builds needs it."
  type        = bool
  default     = false
}

variable "deletion_policy" {
  description = "PREVENT protects the projects from `terraform destroy`; DELETE lets the course be torn down in one command. Set to DELETE only when you mean it."
  type        = string
  default     = "PREVENT"

  validation {
    condition     = contains(["PREVENT", "ABANDON", "DELETE"], var.deletion_policy)
    error_message = "deletion_policy must be PREVENT, ABANDON or DELETE."
  }
}
