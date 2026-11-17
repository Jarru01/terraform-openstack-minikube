output "ipv4_address" {
  description = "Address of the VM on the LXD bridge."
  value       = lxd_instance.this.ipv4_address
}

output "wait_command" {
  description = "Wait for provisioning and check that every node is Ready."
  value       = "./wait-ready.sh ${lxd_instance.this.name} ${var.node_count}"
}

output "shell" {
  description = "Open a shell on the VM as the cluster user."
  value       = "lxc exec ${lxd_instance.this.name} -- sudo -iu ubuntu"
}
