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

variable "instance_name" {
  description = "The name of the compute instance to create."
  type        = string
  validation {
    condition     = length(var.instance_name) > 0 && length(var.instance_name) <= 63
    error_message = "Instance name must be between 1 and 63 characters."
  }
}

variable "service_account" {
  description = "Email of the service account to attach to the instance."
  type        = string
  validation {
    condition     = can(regex("^[a-zA-Z0-9._%+-]+@[a-z0-9.-]+\\.iam\\.gserviceaccount\\.com$", var.service_account))
    error_message = "Must be a valid GCP service account email address."
  }
}

variable "machine_type" {
  description = "The machine type for the compute instance."
  type        = string
  default     = "n2-highmem-4"
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

variable "data_disk_name" {
  description = "The name of the persistent data disk to attach."
  type        = string
  default     = "aria-minecraft-server-data"
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
