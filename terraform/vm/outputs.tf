output "world" {
  description = "The world this state manages"
  value       = var.world
}

output "instance_name" {
  description = "Name of the compute instance for this world"
  value       = google_compute_instance.aria_server.name
}

output "minecraft_version" {
  description = "Minecraft version this world runs"
  value       = local.w.mc_version
}

output "instance_ip" {
  description = "The external IP address of the Minecraft server"
  value       = google_compute_instance.aria_server.network_interface.0.access_config.0.nat_ip
}
