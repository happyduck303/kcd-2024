terraform {
  required_version = ">= v1.6.5"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 5.9.0"
    }
  }
}

variable "network" {
  type = object({
    id   = string
    name = string
  })
}
