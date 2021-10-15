

resource "google_compute_network" "vpc_network" {
  project                 = "active-dahlia-323510"
  name                    = "vpc-network"
  auto_create_subnetworks = true
  mtu                     = 1460
}



