# --- OpenStack placement ------------------------------------------------------

variable "cloud" {
  description = "clouds.yaml entry to use. Leave null to use OS_CLOUD or the OS_* environment variables."
  type        = string
  default     = null
}

variable "name" {
  description = "Base name for all resources."
  type        = string
  default     = "minikube"
}

variable "image_name" {
  description = "Ubuntu image to boot (22.04 or 24.04 cloud image), e.g. \"Ubuntu 24.04\"."
  type        = string
}

variable "flavor_name" {
  description = "Flavor for the VM. Needs roughly node_count x memory_per_node_mb + 1 GB of RAM."
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

# --- Access -------------------------------------------------------------------

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
  description = "Networks allowed to SSH to the VM. Empty means: detect your current public IPv4 address and allow only that /32."
  type        = list(string)
  default     = []

  validation {
    condition     = alltrue([for c in var.admin_cidrs : can(cidrhost(c, 0)) && c != "0.0.0.0/0"])
    error_message = "admin_cidrs must be valid CIDR blocks and must not be 0.0.0.0/0."
  }
}

# --- Cluster ------------------------------------------------------------------

# Passed to modules/cloud-init, which validates them.

variable "minikube_version" {
  description = "minikube release to install."
  type        = string
  default     = "v1.39.0"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster. The default is the version the pinned minikube release defaults to."
  type        = string
  default     = "v1.37.0"
}

variable "node_count" {
  description = "Number of minikube nodes (Docker containers on the one VM), 1-5."
  type        = number
  default     = 3
}

variable "cpus_per_node" {
  description = "CPUs given to each minikube node (at least 2)."
  type        = number
  default     = 2
}

variable "memory_per_node_mb" {
  description = "Memory in MB for each minikube node (at least 1800)."
  type        = number
  default     = 2200
}
