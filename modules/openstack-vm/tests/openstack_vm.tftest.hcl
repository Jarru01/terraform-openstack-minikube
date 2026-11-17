# Unit tests for the module. They run against a mocked OpenStack provider, so
# no cloud or credentials are needed:  terraform init && terraform test

mock_provider "openstack" {
  mock_data "openstack_networking_network_v2" {
    defaults = { id = "11111111-1111-1111-1111-111111111111" }
  }
  mock_data "openstack_images_image_v2" {
    defaults = { id = "22222222-2222-2222-2222-222222222222" }
  }
  mock_data "openstack_compute_flavor_v2" {
    defaults = { id = "33333333-3333-3333-3333-333333333333" }
  }
  mock_resource "openstack_networking_port_v2" {
    defaults = { all_fixed_ips = ["10.0.0.5"] }
  }
  mock_resource "openstack_networking_floatingip_v2" {
    defaults = { address = "203.0.113.50" }
  }
}

variables {
  name           = "test-vm"
  image_name     = "Ubuntu 24.04"
  flavor_name    = "m1.small"
  network_name   = "private"
  ssh_public_key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIExampleKeyForTestsOnly test@example"
  ingress_rules = [
    { description = "ssh", protocol = "tcp", port_min = 22, cidr = "198.51.100.0/24" },
    { description = "ping", protocol = "icmp", cidr = "198.51.100.0/24" },
    { description = "nodeports", protocol = "tcp", port_min = 30000, port_max = 32767, cidr = "198.51.100.0/24" },
    { description = "https-v6", protocol = "tcp", port_min = 443, cidr = "2001:db8::/32" },
  ]
}

run "rules_match_input" {
  command = apply

  assert {
    condition     = length(openstack_networking_secgroup_rule_v2.ingress) == 4
    error_message = "Expected one security group rule per ingress_rules entry."
  }

  assert {
    condition = (
      openstack_networking_secgroup_rule_v2.ingress["0"].port_range_min == 22 &&
      openstack_networking_secgroup_rule_v2.ingress["0"].port_range_max == 22
    )
    error_message = "A rule with only port_min should open exactly that port."
  }

  assert {
    condition     = openstack_networking_secgroup_rule_v2.ingress["2"].port_range_max == 32767
    error_message = "port_max should be passed through for port ranges."
  }

  assert {
    condition     = openstack_networking_secgroup_rule_v2.ingress["3"].ethertype == "IPv6"
    error_message = "IPv6 CIDRs should produce IPv6 rules."
  }

  assert {
    condition     = openstack_networking_secgroup_rule_v2.ingress["0"].ethertype == "IPv4"
    error_message = "IPv4 CIDRs should produce IPv4 rules."
  }
}

run "no_floating_ip_by_default" {
  command = apply

  assert {
    condition     = length(openstack_networking_floatingip_v2.this) == 0
    error_message = "No floating IP should be allocated without floating_ip_pool."
  }

  assert {
    condition     = output.public_ip == "10.0.0.5"
    error_message = "Without a floating IP, public_ip should be the fixed IP."
  }
}

run "floating_ip_when_pool_set" {
  command = apply

  variables {
    floating_ip_pool = "public"
  }

  assert {
    condition     = output.public_ip == "203.0.113.50"
    error_message = "public_ip should be the floating IP when one is allocated."
  }

  assert {
    condition     = output.ssh_command == "ssh ubuntu@203.0.113.50"
    error_message = "ssh_command should target the floating IP."
  }
}

run "rejects_tcp_open_to_world" {
  command = plan

  variables {
    ingress_rules = [{ description = "bad", protocol = "tcp", port_min = 22, cidr = "0.0.0.0/0" }]
  }

  expect_failures = [var.ingress_rules]
}

run "rejects_unknown_protocol" {
  command = plan

  variables {
    ingress_rules = [{ description = "bad", protocol = "gre", cidr = "198.51.100.0/24" }]
  }

  expect_failures = [var.ingress_rules]
}

run "rejects_private_key_or_garbage" {
  command = plan

  variables {
    ssh_public_key = "-----BEGIN OPENSSH PRIVATE KEY-----"
  }

  expect_failures = [var.ssh_public_key]
}
