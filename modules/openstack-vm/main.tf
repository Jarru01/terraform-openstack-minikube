data "openstack_images_image_v2" "this" {
  name        = var.image_name
  most_recent = true
}

data "openstack_compute_flavor_v2" "this" {
  name = var.flavor_name
}

data "openstack_networking_network_v2" "this" {
  name = var.network_name
}

# -----------------------------------------------------------------------------
# Security group: egress stays at the OpenStack default (allow all); ingress is
# exactly what the caller lists in var.ingress_rules.
# -----------------------------------------------------------------------------

resource "openstack_networking_secgroup_v2" "this" {
  name        = "${var.name}-sg"
  description = "Managed by Terraform (${var.name})"
}

resource "openstack_networking_secgroup_rule_v2" "ingress" {
  for_each = { for i, rule in var.ingress_rules : tostring(i) => rule }

  security_group_id = openstack_networking_secgroup_v2.this.id
  description       = each.value.description
  direction         = "ingress"
  ethertype         = strcontains(each.value.cidr, ":") ? "IPv6" : "IPv4"
  protocol          = each.value.protocol
  remote_ip_prefix  = each.value.cidr
  # A single port only needs port_min; no ports at all means "every port".
  port_range_min = each.value.protocol == "icmp" ? null : each.value.port_min
  port_range_max = each.value.protocol == "icmp" ? null : try(coalesce(each.value.port_max, each.value.port_min), null)
}

# -----------------------------------------------------------------------------
# Port, key pair and instance. Creating the port explicitly keeps the security
# group on the port and gives the floating IP something stable to attach to.
# -----------------------------------------------------------------------------

resource "openstack_networking_port_v2" "this" {
  name               = "${var.name}-port"
  network_id         = data.openstack_networking_network_v2.this.id
  admin_state_up     = true
  security_group_ids = [openstack_networking_secgroup_v2.this.id]
}

resource "openstack_compute_keypair_v2" "this" {
  name       = "${var.name}-key"
  public_key = var.ssh_public_key
}

resource "openstack_compute_instance_v2" "this" {
  name      = var.name
  image_id  = data.openstack_images_image_v2.this.id
  flavor_id = data.openstack_compute_flavor_v2.this.id
  key_pair  = openstack_compute_keypair_v2.this.name
  user_data = var.user_data
  metadata  = var.metadata

  network {
    port = openstack_networking_port_v2.this.id
  }

  lifecycle {
    # Changing user_data would rebuild the VM; re-provisioning should be an
    # explicit `terraform apply -replace=...` instead of a side effect.
    ignore_changes = [user_data]
  }
}

resource "openstack_networking_floatingip_v2" "this" {
  count = var.floating_ip_pool == null ? 0 : 1

  pool        = var.floating_ip_pool
  port_id     = openstack_networking_port_v2.this.id
  description = "Managed by Terraform (${var.name})"

  depends_on = [openstack_compute_instance_v2.this]
}

locals {
  fixed_ip  = openstack_networking_port_v2.this.all_fixed_ips[0]
  public_ip = var.floating_ip_pool == null ? local.fixed_ip : openstack_networking_floatingip_v2.this[0].address
}
