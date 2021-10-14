// Configure the Google Cloud provider
provider "google" {
 credentials = file ("my-json.json")
 project     = "active-dahlia-323510"
 region      = "us-west1"
}

# Asingle Compute Engine Instance
resource "google_compute_instance" "default" {
  name = "soumyavm"
  machine_type = "e2-micro"
  zone         = "us-west1-a"

boot_disk {
  initialize_params {
    image = "debian-cloud/debian-10"
  }
}
network_interface {
# A default network is created for all GCP projects
#network = google_compute_network.vpc_network.self_link
  network = "default"

    access_config {
    }
  }
}