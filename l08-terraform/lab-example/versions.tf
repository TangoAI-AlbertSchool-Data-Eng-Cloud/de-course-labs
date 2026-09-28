# ---------------------------------------------------------------------------
# versions.tf - GENERATED, DO NOT EDIT HERE.
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

terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source = "hashicorp/google"
      # 8.3.0 published 2026-09-15; checked on the registry 2026-09-20.
      version = "~> 8.3"
    }
  }

  # Remote state is deliberately NOT configured here yet: the bucket that holds
  # it has to exist before Terraform runs, and it belongs to the school's own
  # project rather than to any group's. See docs/runbook.md, step 2.
  #
  #   backend "gcs" {
  #     bucket = "albert-de-lab-tfstate"
  #     prefix = "lab"
  #   }
}

provider "google" {
  region = var.region
}
