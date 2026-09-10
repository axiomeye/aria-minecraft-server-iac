variable "world" {
  description = "Which world to create. Selects an entry from the worlds map in locals.tf. Each world has its own Terraform state, so applying one never affects another."
  type        = string
  default     = "classic"
  validation {
    condition     = contains(["classic", "cobblemon", "latest"], var.world)
    error_message = "world must be one of: classic, cobblemon, latest."
  }
}

variable "project_id" {
  description = "The ID of the Google Cloud project where resources will be created."
  type        = string
}

variable "region" {
  description = "The GCP region to deploy resources in."
  type        = string
}

variable "zone" {
  description = "The GCP zone for the compute instance."
  type        = string
}

variable "service_account" {
  description = "Email of the service account to attach to the instance."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\\.iam\\.gserviceaccount\\.com$", var.service_account))
    error_message = "Must be a valid GCP service account email address."
  }
}

variable "boot_image" {
  description = "The boot disk image for the compute instance."
  type        = string
  default     = "debian-cloud/debian-13"
}

variable "boot_disk_size_gb" {
  description = "The size of the boot disk in GB."
  type        = number
  default     = 10
  validation {
    condition     = var.boot_disk_size_gb >= 10
    error_message = "Boot disk size must be at least 10 GB."
  }
}

variable "network_name" {
  description = "The name of the VPC network."
  type        = string
  default     = "minecraft-aria-network"
}

variable "subnet_name" {
  description = "The name of the subnet."
  type        = string
  default     = "minecraft-aria-subnet-euw8"
}

// Retained so that the TF_VAR_instance_name / TF_VAR_machine_type /
// TF_VAR_data_disk_name values still set by the GitHub environment do not
// produce "value for undeclared variable" warnings. They are unused: instance
// name, machine type and data disk are now per-world in locals.tf.
variable "instance_name" {
  description = "Deprecated, superseded by the worlds map in locals.tf."
  type        = string
  default     = null
}

variable "machine_type" {
  description = "Deprecated, superseded by the worlds map in locals.tf."
  type        = string
  default     = null
}

variable "data_disk_name" {
  description = "Deprecated, superseded by the worlds map in locals.tf."
  type        = string
  default     = null
}
