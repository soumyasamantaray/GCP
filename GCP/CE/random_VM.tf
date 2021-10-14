// Configure the Google Cloud provider
provider "google" {
 credentials = file ("my-json.json")
 project     = "active-dahlia-323510"
 region      = "us-west1"
}

//Terraform plugin for creating random ids

resource "random_id" "instance_id" {
  byte_length = 8
}

# Asingle Compute Engine Instance
resource "google_compute_instance" "default" {
  name         = "flask-vm-${random_id.instance_id.hex}"
  machine_type = "f1-micro"
  zone         = "us-west1-a"

boot_disk {
  initialize_params {
    image = "debian-cloud/debian-9"
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