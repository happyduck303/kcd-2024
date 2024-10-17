terraform {
  required_version = "~> v1.6"

  required_providers {
    google = {
      source  = "hashicorp/google-beta"
      version = "~> 6.7.0"
    }
  }
}

variable "network" {
  type = object({
    id   = string
    name = string
  })
}
