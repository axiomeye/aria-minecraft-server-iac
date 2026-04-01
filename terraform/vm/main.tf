resource "google_compute_instance" "aria_server" {
  name         = var.instance_name
  machine_type = var.machine_type
  zone         = var.zone
  tags         = ["aria-minecraft-server"]

  boot_disk {
    auto_delete = true
    initialize_params {
      image = var.boot_image
      size  = var.boot_disk_size_gb
      type  = "pd-balanced"
    }
  }

  attached_disk {
    source      = var.data_disk_name
    device_name = "aria-data-disk"
  }

  network_interface {
    network    = var.network_name
    subnetwork = var.subnet_name
    access_config {}
  }

  service_account {
    email  = var.service_account
    scopes = ["cloud-platform"]
  }

  scheduling {
    preemptible                 = true
    automatic_restart           = false
    provisioning_model          = "SPOT"
    instance_termination_action = "DELETE"
  }

  metadata = {
    enable-oslogin  = "TRUE"
    startup-script  = file("./scripts/config.sh")
    shutdown-script = file("./scripts/shutdown.sh")
  }

  labels = {
    app = "aria-minecraft-server"
  }
}

