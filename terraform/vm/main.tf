resource "google_compute_instance" "aria_server" {
  name         = local.w.instance_name
  machine_type = local.w.machine_type
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

  // The data disk is created outside Terraform and only attached here, so it
  // survives any destroy of this instance.
  attached_disk {
    source      = local.w.disk_name
    device_name = local.disk_device_name
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
    enable-oslogin = "TRUE"
    // Read by /opt/scripts/*.sh so auto-destroy and IP notification target the
    // right world. Without this they default to classic and a cobblemon VM
    // would destroy the classic one.
    world = var.world
    startup-script = templatefile("${path.module}/scripts/config.sh.tftpl", {
      world            = var.world
      mc_version       = local.w.mc_version
      memory           = local.w.memory
      image_tag        = local.w.image_tag
      packwiz_url      = local.w.packwiz_url
      disk_device_name = local.disk_device_name

      // Inlined verbatim into the startup script. file() content is injected as
      // a value, not re-parsed as a template, so shell ${...} inside these
      // scripts is safe and needs no escaping.
      auto_destroy_sh    = file("${path.module}/scripts/vm/auto_destroy.sh")
      send_ip_address_sh = file("${path.module}/scripts/vm/send_ip_address.sh")
    })
    shutdown-script = file("${path.module}/scripts/shutdown.sh")
  }

  labels = {
    app   = "aria-minecraft-server"
    world = var.world
  }

  shielded_instance_config {
    enable_integrity_monitoring = true
    enable_secure_boot          = true
    enable_vtpm                 = true
  }
}
