###########################
# naas terraform provider
###########################

terraform {
  required_version = ">= 0.12.6"
  required_providers {
    google = "~> 3.30"
    naas = {
      source = "tfregistry-puuwzmpqva-uc.a.run.app/ford/naas"
      # version               = "~> 0.1.0"
      # source                = "ford.com/networking/naas"
      # configuration_aliases = [naas.naas]
    }
  }
}

###########################
# locals
###########################

locals {
  metadata_default = {    
    google-monitoring-enable = 1
    google-logging-enable    = 1
    enable-oslogin           = var.linux_os_login
    block-project-ssh-keys   = var.block-project-ssh-keys
  }

  shielded_vm_configs          = var.enable_shielded_vm ? [true] : []
  confidential_instance_config = var.enable_confidential_vm ? [true] : []

  gpu_enabled = var.gpu != null

  on_host_maintenance = (
    var.preemptible || var.enable_confidential_vm || local.gpu_enabled
    ? "TERMINATE"
    : var.on_host_maintenance
  )
}

resource "random_id" "instance_id" {
  byte_length = 8
}

###########################
# network
###########################

data "google_compute_subnetwork" "subnet" {
  name    = var.sub_network
  project = var.subnetwork_project
  region  = var.gcp_region
}

resource "naas_hostname" "vm_gethostname" {
  prefix   = var.ddi_prefix
  location = var.ddi_location
  # provider = naas
}

resource "google_compute_address" "static" {
  name         = "static-ip-${random_id.instance_id.hex}"
  project      = var.gcp_project_id
  region       = var.gcp_region
  subnetwork   = data.google_compute_subnetwork.subnet.self_link
  address_type = "INTERNAL"
}

resource "naas_hostworker" "vm_registerhost" {
  hostname = naas_hostname.vm_gethostname.hostname
  location = var.ddi_location
  address  = google_compute_address.static.address
  domain   = var.ddi_domain
  # provider = naas
}


###########################
# extra disks
###########################

resource "google_compute_disk" "additional_disks" {
  project       = var.gcp_project_id
  count         = length(var.extra_disks)
  name          = "${naas_hostname.vm_gethostname.hostname}-${var.extra_disks[count.index].name}"
  type          = var.extra_disks[count.index].disk_type
  size          = var.extra_disks[count.index].disk_size_gb
  zone          = var.gcp_zone
  labels        = var.extra_disks[count.index].disk_labels 

}

##########################
# compute (vm) instance
###########################

resource "google_compute_instance" "vm_instance" {
  project                   = var.gcp_project_id
  name                      = naas_hostname.vm_gethostname.hostname 
  machine_type              = var.machine_type
  zone                      = var.gcp_zone
  allow_stopping_for_update = true
  deletion_protection       = var.deletion_protection
  tags                      = var.instance_tags

  boot_disk {
    auto_delete = var.auto_delete
    initialize_params {
      image       = lookup(var.image, var.os_distro)
      size        = var.boot_disk_size_gb
      type        = var.boot_disk_type     
    }
  }
  dynamic "attached_disk" {
    for_each = google_compute_disk.additional_disks
    content {
      source      = attached_disk.value.self_link
      device_name = attached_disk.value.name
    }
  }

  lifecycle {
    ignore_changes = [attached_disk]
  }

  network_interface {
    subnetwork          = data.google_compute_subnetwork.subnet.self_link
    network_ip          = google_compute_address.static.address
  }

  labels = {
    environment       = var.environment
    offering          = "gce"
    os                = var.os_distro == "win2k19" || var.os_distro == "win2k16" || var.os_distro == "windows" ? "windows" : "linux"
    os_flavor         = element(split("/",lookup(var.image, var.os_distro)),length(split("/",lookup(var.image, var.os_distro)))-1)
    patch             = var.patch_schedule
    maintenance_mode  = var.enable_maintenance_mode
  }

  metadata = merge(local.metadata_default, var.metadata)
  
  metadata_startup_script = var.startup_script

  # scheduling must have automatic_restart be false when preemptible is true.
  scheduling {
    preemptible           = var.preemptible
    automatic_restart     = !var.preemptible
    on_host_maintenance   = local.on_host_maintenance
  }

  dynamic "shielded_instance_config" {
    for_each = local.shielded_vm_configs
    content {
      enable_secure_boot          = lookup(var.shielded_instance_config, "enable_secure_boot", shielded_instance_config.value)
      enable_vtpm                 = lookup(var.shielded_instance_config, "enable_vtpm", shielded_instance_config.value)
      enable_integrity_monitoring = lookup(var.shielded_instance_config, "enable_integrity_monitoring", shielded_instance_config.value)
    }
  }

  confidential_instance_config {
    enable_confidential_compute = var.enable_confidential_vm
  }

  dynamic "guest_accelerator" {
    for_each = local.gpu_enabled ? [var.gpu] : []
    content {
      type  = guest_accelerator.value.type
      count = guest_accelerator.value.count
    }
  }

  dynamic "service_account" {
    for_each = [var.service_account]
    content {
      email  = lookup(service_account.value, "email", null)
      scopes = lookup(service_account.value, "scopes", null)
    }
  }
}