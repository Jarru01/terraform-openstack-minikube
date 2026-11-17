output "user_data" {
  description = "Multipart cloud-init user data (uncompressed, not base64-encoded)."
  value       = data.cloudinit_config.this.rendered
}

output "part_names" {
  description = "Names of the scripts included, in execution order."
  value       = [for p in local.parts : p.filename]
}
