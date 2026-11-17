# --- The local VM ---------------------------------------------------------------

variable "name" {
  description = "Name of the LXD virtual machine."
  type        = string
  default     = "minikube-lxd"
}

variable "image" {
  description = "LXD image for the VM (Ubuntu, so the same cloud-init scripts apply)."
  type        = string
  default     = "ubuntu:24.04"
}

variable "vm_cpus" {
  description = "vCPUs for the VM."
  type        = number
  default     = 4
}

variable "vm_memory" {
  description = "Memory for the VM, in LXD size notation. Needs roughly node_count x memory_per_node_mb + 1 GiB."
  type        = string
  default     = "10GiB"
}

variable "disk_size" {
  description = "Root disk size, in LXD size notation."
  type        = string
  default     = "40GiB"
}

variable "storage_pool" {
  description = "LXD storage pool for the root disk."
  type        = string
  default     = "default"
}

# --- The cluster (passed to modules/cloud-init, which validates them) -----------

variable "minikube_version" {
  description = "minikube release to install."
  type        = string
  default     = "v1.39.0"
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster."
  type        = string
  default     = "v1.37.0"
}

variable "node_count" {
  description = "Number of minikube nodes, 1-5."
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
