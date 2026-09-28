# ---------------------------------------------------------------------------
# outputs.tf - GENERATED, DO NOT EDIT HERE.
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

output "projects" {
  description = "Group key -> project ID. This is what goes on the card you hand each group at the start of L02."
  value       = { for g, p in google_project.group : g => p.project_id }
}

output "project_numbers" {
  description = "Group key -> project number, for anything that needs the numeric form."
  value       = { for g, p in google_project.group : g => p.number }
}

output "console_urls" {
  description = "Group key -> the console link a student opens first."
  value = {
    for g, p in google_project.group :
    g => "https://console.cloud.google.com/welcome?project=${p.project_id}"
  }
}

output "members" {
  description = "Group key -> the accounts granted access, to check against the register before L02."
  value       = var.groups
}

output "gcloud_set_project" {
  description = "The one command each group runs after installing the CLI."
  value = {
    for g, p in google_project.group :
    g => "gcloud config set project ${p.project_id}"
  }
}
