terraform {
  required_version = "~> v1.6"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 6.7.0"
    }
  }
}

variable "name" {
  type = string
}

variable "location" {
  type = string
}

data "google_client_config" "config" {
}

data "google_container_cluster" "cluster" {
  name     = var.name
  location = var.location
}

output "kubeconfig_raw" {
  sensitive = true
  value = templatefile("${path.module}/kubeconfig-template.yaml", {
    endpoint               = data.google_container_cluster.cluster.endpoint
    cluster_ca_certificate = data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate
    token                  = data.google_client_config.config.access_token
  })
}

output "config" {
  sensitive = true
  value = {
    host                   = "https://${data.google_container_cluster.cluster.endpoint}"
    cluster_ca_certificate = base64decode(data.google_container_cluster.cluster.master_auth[0].cluster_ca_certificate)
    token                  = data.google_client_config.config.access_token
  }
}
