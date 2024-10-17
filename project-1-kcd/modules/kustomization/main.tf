terraform {
  required_version = "~> v1.4"

  required_providers {
    kustomization = {
      source  = "kbst/kustomization"
      version = "~> 0.9.2"
    }
  }
}

variable "resources" {
  type = list(string)
}

data "kustomization_overlay" "top" {
  resources = var.resources
}

resource "kustomization_resource" "p0" {
  for_each = data.kustomization_overlay.top.ids_prio[0]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_overlay.top.manifests[each.value])
    : data.kustomization_overlay.top.manifests[each.value]
  )
}

resource "kustomization_resource" "p1" {
  depends_on = [kustomization_resource.p0]

  for_each = data.kustomization_overlay.top.ids_prio[1]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_overlay.top.manifests[each.value])
    : data.kustomization_overlay.top.manifests[each.value]
  )

  wait = true

  timeouts {
    create = "30m"
    update = "30m"
    delete = "30m"
  }
}

resource "kustomization_resource" "p2" {
  depends_on = [kustomization_resource.p1]

  for_each = data.kustomization_overlay.top.ids_prio[2]

  manifest = (
    contains(["_/Secret"], regex("(?P<group_kind>.*/.*)/.*/.*", each.value)["group_kind"])
    ? sensitive(data.kustomization_overlay.top.manifests[each.value])
    : data.kustomization_overlay.top.manifests[each.value]
  )
}
