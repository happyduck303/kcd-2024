terraform {
  required_version = "~> v1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 5.9"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "~> 2.24"
    }
  }

  backend "gcs" {
    bucket = "kcd-indonesia-2024"
    prefix = "kcd-project-1/gke/prome-primary"
  }
}

locals {
  project = "kcd-project-1"
  region  = "asia-southeast2"
}

provider "google" {
  project = local.project
  region  = local.region
}

resource "google_service_account" "gke-prome-primary" {
  account_id   = "gke-prome-primary"
  display_name = "gke-prome-primary"
  description  = "used by gke prome-primary"
}

resource "google_project_iam_member" "gke-prome-primary" {
  for_each = toset([
    "roles/artifactregistry.reader",
    "roles/container.nodeServiceAccount",
  ])

  project = local.project
  role    = each.value
  member  = "serviceAccount:${google_service_account.gke-prome-primary.email}"
}

resource "google_project_service" "container" {
  project            = local.project
  service            = "container.googleapis.com"
  disable_on_destroy = false
}

resource "google_container_cluster" "cluster" {
  depends_on = [google_project_service.container]
  deletion_protection = false

  name = "cluster-infra"


  # networking

  location   = local.region
  network    = "default"
  subnetwork = "default"
  ip_allocation_policy {
    cluster_secondary_range_name  = "pods"
    services_secondary_range_name = "services"
  }
  # private_cluster_config {
  #   enable_private_endpoint = true
  #   enable_private_nodes    = true
  #   master_ipv4_cidr_block  = "10.233.36.144/28"
  # }
  default_snat_status {
    disabled = true
  }
  # master_authorized_networks_config {
  #   gcp_public_cidrs_access_enabled = false
  #   cidr_blocks {
  #     display_name = "temporary-debug"
  #     cidr_block   = "10.233.17.2/32"
  #   }
  # }


  # gke feature

  enable_l4_ilb_subsetting    = true
  enable_intranode_visibility = true
  datapath_provider           = "ADVANCED_DATAPATH"
  default_max_pods_per_node   = 32
  workload_identity_config {
    workload_pool = "${local.project}.svc.id.goog"
  }
  cluster_autoscaling {
    autoscaling_profile = "OPTIMIZE_UTILIZATION"
    # we don't use auto create of node pool, we manage our own node pools
    enabled = false
  }
  dns_config {
    cluster_dns       = "CLOUD_DNS"
    cluster_dns_scope = "CLUSTER_SCOPE"
  }
  gateway_api_config {
    channel = "CHANNEL_STANDARD"
  }
  node_pool_defaults {
    node_config_defaults {
      gcfs_config {
        enabled = true
      }
    }
  }
  vertical_pod_autoscaling {
    enabled = true
  }
  security_posture_config {
    vulnerability_mode = "VULNERABILITY_BASIC"
  }
  addons_config {
    dns_cache_config {
      enabled = true
    }
  }
  # monitoring_config {
  #   enable_components = ["SYSTEM_COMPONENTS"]
  #   managed_prometheus { enabled = true }
  #   advanced_datapath_observability_config { enable_metrics = true }
  # }
  logging_config {
    enable_components = ["SYSTEM_COMPONENTS", "WORKLOADS"]
  }


  # cluster upgrade

  release_channel {
    channel = "REGULAR"
  }
  maintenance_policy {
    recurring_window {
      recurrence = "FREQ=DAILY"
      start_time = "2023-01-01T18:00:00Z"
      end_time   = "2023-01-01T22:00:00Z"
    }
  }


  # initial nodes

  initial_node_count       = 1
  remove_default_node_pool = true
  node_config {
    disk_size_gb = "10"
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }


  lifecycle {
    # as we using remove_default_node_pool
    # the node_config will be invalid after cluster creation
    ignore_changes = [node_config]
  }
}

locals {
  pools = [
    "e2-standard-4",
  ]
}

resource "google_container_node_pool" "pool" {
  for_each = {
    for p in local.pools : "${p}" => { machine_type = p }
  }

  name     = each.key
  cluster  = google_container_cluster.cluster.name
  location = google_container_cluster.cluster.location

  autoscaling {
    total_min_node_count = 0
    total_max_node_count = 25
  }

  node_config {
    machine_type    = each.value.machine_type
    service_account = google_service_account.gke-prome-primary.email
    oauth_scopes    = ["https://www.googleapis.com/auth/cloud-platform"]
    disk_type       = "pd-standard"
    gvnic {
      enabled = true
    }
    shielded_instance_config {
      enable_secure_boot          = true
      enable_integrity_monitoring = true
    }
  }
}
