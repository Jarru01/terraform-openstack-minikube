output "ipv4_address" {
  description = "Address of the VM on the LXD bridge."
  value       = lxd_instance.this.ipv4_address
}

output "nodes" {
  description = "`kubectl get nodes -o wide`, captured right after the cluster became Ready."
  value       = lxd_instance.this.execs["30-get-nodes"].stdout
}

output "shell" {
  description = "Open a shell on the VM as the cluster user."
  value       = "lxc exec ${lxd_instance.this.name} -- sudo -iu ubuntu"
}
