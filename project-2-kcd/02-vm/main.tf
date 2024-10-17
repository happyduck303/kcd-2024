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
    prefix = "project-2-kcd-vm-temporary-debug"
  }
}

locals {
  project = "project-2-kcd"
  region  = "asia-southeast2"
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_compute_instance" "temporary-debug" {
  name           = "temporary-debug"
  project        = local.project
  machine_type   = "e2-micro"
  zone           = "asia-southeast2-b"
  can_ip_forward = true
  tags           = ["temporary-debug"]
  boot_disk {
    auto_delete = true
    device_name = "dev_disk"
    mode        = "READ_WRITE"

    initialize_params {
      image = "ubuntu-os-cloud/ubuntu-minimal-2204-jammy-v20230907"
      size  = 10
      type  = "pd-balanced"
    }
  }

  network_interface {
    network    = "projects/project-2-kcd/global/networks/default"
    subnetwork = "projects/project-2-kcd/regions/asia-southeast2/subnetworks/default"
  }
  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }
}
