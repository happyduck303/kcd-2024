terraform {
  required_version = "~> v1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0.0"
    }
  }

  backend "gcs" {
    bucket = "kcd-2024"
    prefix = "project-kcd-2/project"
  }
}


# Project
resource "google_project" "project" {
  name            = "project-kcd-2"
  project_id      = "project-kcd-2"
  billing_account = "013B4E-C45A90-87469C"
}


# Enable API service
resource "google_project_service" "enabled_service" {
  project = google_project.project.project_id

  for_each = toset([
    "compute.googleapis.com",
    "container.googleapis.com",
    "cloudresourcemanager.googleapis.com",
  ])

  service            = each.value
  disable_on_destroy = false
}
