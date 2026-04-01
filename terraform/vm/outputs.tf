output "instance_ip" {
  description = "The external IP address of the Minecraft server"
  value       = google_compute_instance.aria_server.network_interface.0.access_config.0.nat_ip
}
