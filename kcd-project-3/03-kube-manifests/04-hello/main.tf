terraform {
  required_version = "~> 1.6.0"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 6.7.0"
    }
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9.5"
    }
  }
  backend "gcs" {
    bucket = "kcd-indonesia-2024"
    prefix = "kcd-project-3/kube/snake-game"
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

module "gkeauth" {
  source = "../../../modules/gke-auth-v2"

  name     = "cluster-prod-3"
  location = local.region
}

provider "kustomization" {
  kubeconfig_raw = module.gkeauth.kubeconfig_raw
}

module "ingress" {
  source = "../../../modules/kustomization"
  providers = {
    kustomization = kustomization
  }

  resources = ["./manifests"]
}
