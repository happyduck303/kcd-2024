# allow `gcloud compute ssh --tunnel-through-iap`
resource "google_compute_firewall" "allow-ssh-from-iap" {
  name    = "${var.network.name}-allow-ssh-from-iap"
  network = var.network.id

  source_ranges = ["35.235.240.0/20"]
  allow {
    protocol = "tcp"
    ports    = ["22"]
  }
}

# allow access from gcp infra, like healthcheck, vpc connector, etc
resource "google_compute_firewall" "allow-gcp-infra-4" {
  name    = "${var.network.name}-allow-gcp-infra-4"
  network = var.network.id

  source_ranges = [
    "35.191.0.0/16",
    "35.199.224.0/19",
    "107.178.230.64/26",
    "108.170.220.0/23",
    "130.211.0.0/22",
    "209.85.152.0/22",
    "209.85.204.0/22",
  ]
  allow {
    protocol = "all"
  }
}

# allow access from gcp infra, like healthcheck, vpc connector, etc
resource "google_compute_firewall" "allow-gcp-infra-6" {
  name    = "${var.network.name}-allow-gcp-infra-6"
  network = var.network.id

  source_ranges = [
    "2600:2d00:1:b029::/64",
    "2600:1901:8001::/48",
  ]
  allow {
    protocol = "all"
  }
}

# ini dipake sama router instance, atau buat debugging
# in case of router instance, dia harus setup proper iptables on top of rule ini
resource "google_compute_firewall" "i-allow-rfc1918" {
  name    = "${var.network.name}-i-allow-rfc1918"
  network = var.network.id

  direction = "INGRESS"

  target_tags = ["allow-rfc1918"]

  source_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
  allow {
    protocol = "all"
  }
}
resource "google_compute_firewall" "e-allow-rfc1918" {
  name    = "${var.network.name}-e-allow-rfc1918"
  network = var.network.id

  direction = "EGRESS"

  target_tags = ["allow-rfc1918"]

  source_ranges = [
    "10.0.0.0/8",
    "172.16.0.0/12",
    "192.168.0.0/16",
  ]
  allow {
    protocol = "all"
  }
}
