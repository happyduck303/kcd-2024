terraform {
  required_version = "~> v1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 5.0.0"
    }
  }

  backend "gcs" {
    bucket = "kcd-indonesia-2024"
    prefix = "kcd-project-1/project"
  }
}


# Project
resource "google_project" "project" {
  name            = "kcd-project-1"
  project_id      = "kcd-project-1"
  billing_account = "013D39-9769EE-A82870"
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


# vpc peering dari kcd-project-1 (default) ke kcd-project-2 (default)
resource "google_compute_network_peering" "peering-to-kcd-project-2" {
  name         = "peering-to-kcd-project-2"
  network      = "https://www.googleapis.com/compute/v1/projects/kcd-project-1/global/networks/default"
  peer_network = "https://www.googleapis.com/compute/v1/projects/kcd-project-2/global/networks/default"
}


# vpc peering dari kcd-project-1 (default) ke kcd-project-3 (default)
resource "google_compute_network_peering" "peering-to-kcd-project-3" {
  name         = "peering-to-kcd-project-3"
  network      = "https://www.googleapis.com/compute/v1/projects/kcd-project-1/global/networks/default"
  peer_network = "https://www.googleapis.com/compute/v1/projects/kcd-project-3/global/networks/default"
}
