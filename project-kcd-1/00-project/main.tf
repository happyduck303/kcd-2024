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
    prefix = "project-kcd-1/project"
  }
}


# Project
resource "google_project" "project" {
  name            = "project-kcd-1"
  project_id      = "project-kcd-1"
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


# vpc peering dari project-kcd-1 (default) ke project-kcd-2 (default)
resource "google_compute_network_peering" "peering-to-project-kcd-2" {
  name         = "peering-to-project-kcd-2"
  network      = "https://www.googleapis.com/compute/v1/projects/project-kcd-1/global/networks/default"
  peer_network = "https://www.googleapis.com/compute/v1/projects/project-kcd-2/global/networks/default"
}


# vpc peering dari project-kcd-1 (default) ke project-kcd-3 (default)
resource "google_compute_network_peering" "peering-to-project-kcd-3" {
  name         = "peering-to-project-kcd-3"
  network      = "https://www.googleapis.com/compute/v1/projects/project-kcd-1/global/networks/default"
  peer_network = "https://www.googleapis.com/compute/v1/projects/project-kcd-3/global/networks/default"
}
