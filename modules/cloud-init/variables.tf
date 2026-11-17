variable "ssh_user" {
  description = "Login user of the image. Gets Docker access and runs minikube."
  type        = string
  default     = "ubuntu"
}

variable "install_minikube" {
  description = "Install kubectl and minikube and start the cluster. false = Docker host only."
  type        = bool
  default     = true
}

variable "minikube_version" {
  description = "minikube release to install."
  type        = string
  default     = "v1.39.0"

  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+$", var.minikube_version))
    error_message = "minikube_version must look like v1.39.0."
  }
}

variable "kubernetes_version" {
  description = "Kubernetes version for the cluster. The default is the version the pinned minikube release defaults to."
  type        = string
  default     = "v1.37.0"

  validation {
    condition     = can(regex("^v\\d+\\.\\d+\\.\\d+$", var.kubernetes_version))
    error_message = "kubernetes_version must look like v1.37.0."
  }
}

variable "node_count" {
  description = "Number of minikube nodes (Docker containers on the one VM)."
  type        = number
  default     = 3

  validation {
    condition     = var.node_count >= 1 && var.node_count <= 5
    error_message = "node_count must be between 1 and 5."
  }
}

variable "cpus_per_node" {
  description = "CPUs given to each minikube node (minikube requires at least 2)."
  type        = number
  default     = 2

  validation {
    condition     = var.cpus_per_node >= 2
    error_message = "minikube needs at least 2 CPUs per node."
  }
}

variable "memory_per_node_mb" {
  description = "Memory in MB for each minikube node (minikube requires at least 1800)."
  type        = number
  default     = 2200

  validation {
    condition     = var.memory_per_node_mb >= 1800
    error_message = "minikube needs at least 1800 MB per node."
  }
}
