terraform {
  required_version = ">= 1.9"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "~> 8.4"
    }
  }

  # State is kept in the repository alongside the configuration, so that every
  # member of the team has the current state and can apply from their own
  # machine without additional setup.
}

provider "google" {
  project = var.project_id
  region  = "europe-west1"
}

variable "project_id" {
  type = string
}

resource "google_storage_bucket" "bronze" {
  name                        = "albert-marketplace-bronze"
  location                    = "EUROPE-WEST1"
  uniform_bucket_level_access = true
  force_destroy               = false

  versioning {
    enabled = true
  }

  lifecycle_rule {
    condition {
      age = 90
    }
    action {
      type          = "SetStorageClass"
      storage_class = "NEARLINE"
    }
  }
}

resource "google_bigquery_dataset" "silver" {
  dataset_id = "silver"
  location   = "europe-west1"
}

resource "google_bigquery_dataset" "gold" {
  dataset_id = "gold"
  location   = "europe-west1"
}

resource "google_service_account" "pipeline" {
  account_id   = "marketplace-pipeline"
  display_name = "Marketplace pipeline"
}

resource "google_storage_bucket_iam_member" "pipeline_bronze" {
  bucket = google_storage_bucket.bronze.name
  role   = "roles/storage.objectAdmin"
  member = "serviceAccount:${google_service_account.pipeline.email}"
}

resource "google_bigquery_dataset_iam_member" "analysts_gold" {
  dataset_id = google_bigquery_dataset.gold.dataset_id
  role       = "roles/bigquery.dataViewer"
  member     = "group:analysts@example.com"
}

resource "google_billing_budget" "platform" {
  billing_account = var.billing_account
  display_name    = "Marketplace platform"

  budget_filter {
    projects = ["projects/${var.project_id}"]
  }

  amount {
    specified_amount {
      currency_code = "EUR"
      units         = "500"
    }
  }

  threshold_rules {
    threshold_percent = 1.0
  }
}

variable "billing_account" {
  type = string
}
