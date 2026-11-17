variable "cloud" {
  description = "clouds.yaml entry to use. Leave null to use OS_CLOUD or the OS_* environment variables."
  type        = string
  default     = null
}

variable "name" {
  description = "Base name for all resources."
  type        = string
  default     = "docker-host"
}

variable "image_name" {
  description = "Ubuntu image to boot (22.04 or 24.04 cloud image), e.g. \"Ubuntu 24.04\"."
  type        = string
}

variable "flavor_name" {
  description = "Flavor for the VM."
  type        = string
}

variable "network_name" {
  description = "Network for the VM's port."
  type        = string
}

variable "floating_ip_pool" {
  description = "External network for a floating IP. Leave null if network_name is already reachable from your machine."
  type        = string
  default     = null
}

variable "ssh_public_key_path" {
  description = "Path to the OpenSSH public key to install on the VM."
  type        = string
  default     = "~/.ssh/id_ed25519.pub"

  validation {
    condition     = fileexists(pathexpand(var.ssh_public_key_path))
    error_message = "No public key at ssh_public_key_path. Create one with `ssh-keygen -t ed25519` or point the variable at an existing .pub file."
  }
}

variable "ssh_user" {
  description = "Default user of the image."
  type        = string
  default     = "ubuntu"
}

variable "admin_cidrs" {
  description = "Networks allowed to reach the VM. Empty means: detect your current public IPv4 address and allow only that /32."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0)) && c != "0.0.0.0/0"])
    error_message = "admin_cidrs must be valid CIDR blocks and must not be 0.0.0.0/0."
  }
}

variable "app_tcp_ports" {
  description = "Extra TCP ports (e.g. published container ports) opened to admin_cidrs."
  type        = list(number)
  default     = []

  validation {
    condition     = alltrue([for p in var.app_tcp_ports : p >= 1 && p <= 65535 && p != 22])
    error_message = "app_tcp_ports must be valid TCP ports other than 22 (SSH is always open to admin_cidrs)."
  }
}
