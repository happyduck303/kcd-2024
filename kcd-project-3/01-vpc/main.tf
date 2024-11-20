terraform {
  required_version = "~> v1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 6.7.0"
    }
  }

  backend "gcs" {
    bucket = "kcd-indonesia-2024"
    prefix = "kcd-project-3/vpc"
  }
}

locals {
  project = "kcd-project-3"
  region  = "asia-southeast2"
}

provider "google" {
  project = local.project
  region  = local.region
}

locals {
  named-range = {
    "default"          = "10.233.29.0/24",
    "default/pods"     = "10.233.160.0/22",
    "default/services" = "10.233.164.0/24",
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



# firewall

module "common_firewall" {
  source = "../../modules/gcp-common-firewall-v2"
  providers = {
    google = google
  }

  network = google_compute_network.default
}

## block private ip by default
resource "google_compute_firewall" "block-private-ip" {
  name    = "${google_compute_network.default.name}-block-private-ip"
  network = google_compute_network.default.id

  direction = "EGRESS"

  destination_ranges = [
    # rfc 1918
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",

    # rfc 6598
    "100.64.0.0/10",
  ]

  deny {
    protocol = "all"
  }

  priority = 9000

  log_config {
    metadata = "INCLUDE_ALL_METADATA"
  }
}

locals {
  firewall-spec = yamldecode(file("./firewall.yaml"))
  resolved-range = merge(flatten([
    [for _, fw in local.firewall-spec : [
      [for range in fw.from : { "${range}" = range } if can(cidrnetmask(range))],
      [for range in fw.to : { "${range}" = range } if can(cidrnetmask(range))],
    ]],
    [for name, cidr in local.named-range : { "${name}" = cidr }],
  ])...)
  translated-firewall = merge(flatten([
    {
      for name, rule in local.firewall-spec :
      name => {
        from = sort([for v in rule.from : local.resolved-range[v]]),
        to   = sort([for v in rule.to : local.resolved-range[v]]),
      }
    },
    {
      "temporary-debug" : {
        from = ["10.233.18.2/32"]
        to   = ["0.0.0.0/0"]
      }
    }
  ])...)
}

resource "google_compute_firewall" "ingress" {
  for_each = local.translated-firewall

  name      = "${google_compute_network.default.name}-i-${each.key}"
  network   = google_compute_network.default.id
  direction = "INGRESS"

  source_ranges      = each.value.from
  destination_ranges = each.value.to
  allow {
    protocol = "all"
  }
}

resource "google_compute_firewall" "egress" {
  for_each = local.translated-firewall

  name      = "${google_compute_network.default.name}-e-${each.key}"
  network   = google_compute_network.default.id
  direction = "EGRESS"

  source_ranges      = each.value.from
  destination_ranges = each.value.to
  allow {
    protocol = "all"
  }
}
