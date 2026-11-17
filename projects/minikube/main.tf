# -----------------------------------------------------------------------------
# Who may connect: explicit admin_cidrs, or the caller's current public IP.
# -----------------------------------------------------------------------------

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
  # The lookup service answers with a trailing newline, hence chomp().
  admin_cidrs = length(var.admin_cidrs) > 0 ? var.admin_cidrs : ["${chomp(data.http.my_ip[0].response_body)}/32"]

  # Read the key only if it exists, so a missing file is reported by the
  # variable validation (with a helpful message) rather than by file().
  ssh_public_key_file = pathexpand(var.ssh_public_key_path)
  ssh_public_key      = fileexists(local.ssh_public_key_file) ? trimspace(file(local.ssh_public_key_file)) : ""
}

# -----------------------------------------------------------------------------
# Provisioning: shared with the local LXD variant (projects/minikube-lxd)
# -----------------------------------------------------------------------------

module "cloud_init" {
  source = "../../modules/cloud-init"

  ssh_user           = var.ssh_user
  minikube_version   = var.minikube_version
  kubernetes_version = var.kubernetes_version
  node_count         = var.node_count
  cpus_per_node      = var.cpus_per_node
  memory_per_node_mb = var.memory_per_node_mb
}

# -----------------------------------------------------------------------------
# The VM
# -----------------------------------------------------------------------------

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
  )

  metadata = {
    role               = "minikube"
    kubernetes_version = var.kubernetes_version
    minikube_nodes     = tostring(var.node_count)
  }
}

# -----------------------------------------------------------------------------
# Sizing sanity check (warns during plan, does not block)
# -----------------------------------------------------------------------------

data "openstack_compute_flavor_v2" "selected" {
  name = var.flavor_name
}

check "flavor_fits_cluster" {
  assert {
    condition     = data.openstack_compute_flavor_v2.selected.ram >= var.node_count * var.memory_per_node_mb + 1024
    error_message = "Flavor ${var.flavor_name} has ${data.openstack_compute_flavor_v2.selected.ram} MB RAM; ${var.node_count} nodes x ${var.memory_per_node_mb} MB + 1 GB for the OS needs ${var.node_count * var.memory_per_node_mb + 1024} MB."
  }

  assert {
    condition     = data.openstack_compute_flavor_v2.selected.vcpus >= var.cpus_per_node
    error_message = "Flavor ${var.flavor_name} has ${data.openstack_compute_flavor_v2.selected.vcpus} vCPUs; each minikube node is configured for ${var.cpus_per_node}."
  }
}
