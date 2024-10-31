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

# ILB for prometheus-ilb
resource "google_compute_address" "prometheus-ilb" {
  project      = google_project.project.name
  name         = "prometheus-ilb"
  address_type = "INTERNAL"
  subnetwork   = "default"
  region       = "asia-southeast2"
}

# vpc peering dari project-kcd-2 (default) ke project-kcd-1 (default)
resource "google_compute_network_peering" "peering-to-project-kcd-1" {
  name         = "peering-to-project-kcd-1"
  network      = "https://www.googleapis.com/compute/v1/projects/project-kcd-2/global/networks/default"
  peer_network = "https://www.googleapis.com/compute/v1/projects/project-kcd-1/global/networks/default"
}
