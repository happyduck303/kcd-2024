terraform {
  required_version = "~> v1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 6.7.0"
    }
  }

  backend "gcs" {
    bucket = "kcd-tfstate"
    prefix = "project-1-kcd-vpc"
  }
}

locals {
  project = "project-1-kcd"
  region  = "asia-southeast2"
}

provider "google" {
  project = local.project
  region  = local.region
}

locals {
  named-range = {
    "default"          = "10.233.17.0/24",
    "default/pods"     = "10.233.64.0/22",
    "default/services" = "10.233.55.0/24",
  }
}


# VPC

resource "google_compute_network" "default" {
  name                    = "default"
  auto_create_subnetworks = false
}

resource "google_compute_router" "default" {
  name    = "default"
  network = google_compute_network.default.id
  region  = local.region
}

resource "google_compute_router_nat" "default" {
  name                               = "default"
  router                             = google_compute_router.default.name
  region                             = google_compute_router.default.region
  nat_ip_allocate_option             = "AUTO_ONLY"
  source_subnetwork_ip_ranges_to_nat = "ALL_SUBNETWORKS_ALL_IP_RANGES"
}


# default subnet

resource "google_compute_subnetwork" "default" {
  name          = "default"
  network       = google_compute_network.default.id
  region        = local.region
  ip_cidr_range = local.named-range["default"]
  secondary_ip_range {
    range_name    = "pods"
    ip_cidr_range = local.named-range["default/pods"]
  }
  secondary_ip_range {
    range_name    = "services"
    ip_cidr_range = local.named-range["default/services"]
  }
}
