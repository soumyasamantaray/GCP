// Configure the Google Cloud provider
provider "google" {
 credentials = file("file_name.json")
 project     = "project_name"
 region      = "us-west1"
}

resource "google_compute_network" "vpc_network" {
  project                 = "my-project-name"
  name                    = "vpc-network"
  auto_create_subnetworks = true
  mtu                     = 1460
}

