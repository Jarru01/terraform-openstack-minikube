output "public_ip" {
  description = "Address to connect to."
  value       = module.vm.public_ip
}

output "ssh_command" {
  description = "SSH into the VM."
  value       = module.vm.ssh_command
}

output "admin_cidrs" {
  description = "Networks allowed to reach the VM."
  value       = local.admin_cidrs
}

output "next_steps" {
  description = "How to check that provisioning finished."
  value       = <<-EOT
    ${module.vm.ssh_command} 'cloud-init status --wait && docker version'
  EOT
}
