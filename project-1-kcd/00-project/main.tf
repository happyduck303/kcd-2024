terraform {
  required_version = "~> v1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0.0"
    }
  }

  backend "gcs" {
    bucket = "kcd-tfstate"
    prefix = "project-1-kcd-proj"
  }
}


# Project
resource "google_project" "project" {
  name            = "project-1-kcd"
  project_id      = "project-1-kcd"
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
