# A lighter variant of the minikube project: the same module and base
# provisioning, but the VM stops after installing Docker Engine.

data "http" "my_ip" {
  count = length(var.admin_cidrs) == 0 ? 1 : 0
  url   = "https://checkip.amazonaws.com"

  lifecycle {
    postcondition {
      condition     = self.status_code == 200 && can(cidrhost("${chomp(self.response_body)}/32", 0))
      error_message = "Could not detect your public IPv4 address; set admin_cidrs explicitly."
    }
  }
}

locals {
  admin_cidrs = length(var.admin_cidrs) > 0 ? var.admin_cidrs : ["${chomp(data.http.my_ip[0].response_body)}/32"]

  # Read the key only if it exists, so a missing file is reported by the
  # variable validation (with a helpful message) rather than by file().
  ssh_public_key_file = pathexpand(var.ssh_public_key_path)
  ssh_public_key      = fileexists(local.ssh_public_key_file) ? trimspace(file(local.ssh_public_key_file)) : ""
}

module "cloud_init" {
  source = "../../modules/cloud-init"

  ssh_user         = var.ssh_user
  install_minikube = false
}

module "vm" {
  source = "../../modules/openstack-vm"

  name             = var.name
  image_name       = var.image_name
  flavor_name      = var.flavor_name
  network_name     = var.network_name
  floating_ip_pool = var.floating_ip_pool
  ssh_user         = var.ssh_user
  ssh_public_key   = local.ssh_public_key
  user_data        = module.cloud_init.user_data

  ingress_rules = concat(
    [for cidr in local.admin_cidrs : { description = "SSH from admin network", protocol = "tcp", port_min = 22, cidr = cidr }],
    [for cidr in local.admin_cidrs : { description = "ICMP from admin network", protocol = "icmp", cidr = cidr }],
    flatten([
      for port in var.app_tcp_ports : [
        for cidr in local.admin_cidrs : { description = "App port ${port}", protocol = "tcp", port_min = port, cidr = cidr }
      ]
    ]),
  )

  metadata = {
    role = "docker-host"
  }
}
