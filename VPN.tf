resource "google_compute_router" "cr-uscentral1-to-prod-vpc" {
  name    = "cr-uscentral1-to-prod-vpc-tunnels"
  region  = "us-central1"
  network = "default"
  project = "active-dahlia-323510"

  bgp {
    asn = "64519"
  }
}

module "vpn-prod-internal" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.2.0"

  project_id         = "active-dahlia-323510"
  network            = "default"
  region             = "us-west1"
  gateway_name       = "vpn-prod-internal"
  tunnel_name_prefix = "vpn-tn-prod-internal"
  shared_secret      = "secrets"
  tunnel_count       = 1
  peer_ips           = ["1.1.1.1", "2.2.2.2"]

  route_priority = 1000
  remote_subnet  = ["10.17.0.0/22", "10.16.80.0/24"]
}

module "vpn-manage-internal" {
  source  = "terraform-google-modules/vpn/google"
  version = "~> 1.2.0"
  project_id         = "active-dahlia-323510"
  network            = "default"
  region             = "us-west1"
  gateway_name       = "vpn-manage-internal"
  tunnel_name_prefix = "vpn-tn-manage-internal"
  shared_secret      = "secrets"
  tunnel_count       = 1
  peer_ips           = ["1.1.1.1", "2.2.2.2"]

  route_priority = 1000
  remote_subnet  = ["10.17.32.0/20", "10.17.16.0/20"]
}