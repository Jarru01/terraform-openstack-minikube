variable "name" {
  description = "Base name for every resource the module creates."
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]{1,40}$", var.name))
    error_message = "name must be 2-41 characters of lowercase letters, digits and dashes."
  }
}

variable "image_name" {
  description = "Name of the Glance image to boot."
  type        = string
}

variable "flavor_name" {
  description = "Name of the Nova flavor."
  type        = string
}

variable "network_name" {
  description = "Name of the Neutron network for the instance port."
  type        = string
}

variable "floating_ip_pool" {
  description = "External network to allocate a floating IP from. Leave null when network_name is already publicly routable."
  type        = string
  default     = null
}

variable "ssh_public_key" {
  description = "OpenSSH public key installed for the image's default user. Only the public half ever reaches Terraform state."
  type        = string

  validation {
    condition     = can(regex("^(ssh-(ed25519|rsa)|ecdsa-sha2-nistp(256|384|521)) ", var.ssh_public_key))
    error_message = "ssh_public_key must be an OpenSSH public key (ssh-ed25519, ssh-rsa or ecdsa-sha2-*)."
  }
}

variable "ingress_rules" {
  description = "Inbound rules for the instance's security group. Omit port_min/port_max for ICMP or to allow all ports."
  type = list(object({
    description = string
    protocol    = string
    cidr        = string
    port_min    = optional(number)
    port_max    = optional(number)
  }))
  default = []

  validation {
    condition     = alltrue([for r in var.ingress_rules : contains(["tcp", "udp", "icmp"], r.protocol)])
    error_message = "protocol must be one of tcp, udp or icmp."
  }

  validation {
    condition     = alltrue([for r in var.ingress_rules : can(cidrhost(r.cidr, 0))])
    error_message = "Every cidr must be a valid IPv4 or IPv6 CIDR block."
  }

  validation {
    condition     = alltrue([for r in var.ingress_rules : r.cidr != "0.0.0.0/0" || r.protocol == "icmp"])
    error_message = "Refusing to open tcp/udp to 0.0.0.0/0; list the networks that need access instead."
  }
}

variable "user_data" {
  description = "cloud-init user data passed to the instance."
  type        = string
  default     = null
}

variable "ssh_user" {
  description = "Default login user of the image; only used to build the ssh_command output."
  type        = string
  default     = "ubuntu"
}

variable "metadata" {
  description = "Key/value metadata attached to the instance."
  type        = map(string)
  default     = {}
}
