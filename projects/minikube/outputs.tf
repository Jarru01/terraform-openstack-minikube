output "public_ip" {
  description = "Address to connect to."
  value       = module.vm.public_ip
}

output "ssh_command" {
  description = "SSH into the VM."
  value       = module.vm.ssh_command
}

output "admin_cidrs" {
  description = "Networks allowed to SSH in."
  value       = local.admin_cidrs
}

output "next_steps" {
  description = "How to check that provisioning finished and the cluster is up."
  value       = <<-EOT
    # Provisioning takes a few minutes after the VM boots:
    ${module.vm.ssh_command} 'cloud-init status --wait && kubectl get nodes'

    # Provisioning log on the VM:
    ${module.vm.ssh_command} 'sudo tail -n 50 /var/log/cloud-init-output.log'
  EOT
}
