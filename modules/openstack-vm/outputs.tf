output "instance_id" {
  description = "Nova ID of the instance."
  value       = openstack_compute_instance_v2.this.id
}

output "fixed_ip" {
  description = "Address of the instance on var.network_name."
  value       = local.fixed_ip
}

output "public_ip" {
  description = "Address to connect to: the floating IP if one was allocated, otherwise the fixed IP."
  value       = local.public_ip
}

output "security_group_id" {
  description = "ID of the instance's security group, for adding rules from the caller."
  value       = openstack_networking_secgroup_v2.this.id
}

output "ssh_command" {
  description = "SSH command for the instance (uses the private key matching var.ssh_public_key)."
  value       = "ssh ${var.ssh_user}@${local.public_ip}"
}
