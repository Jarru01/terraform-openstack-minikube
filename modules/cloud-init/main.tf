# Provider-agnostic provisioning: the same user data is used for OpenStack
# instances and for local LXD virtual machines. cloud-init runs the parts in
# filename order.

locals {
  scripts = "${path.module}/scripts"

  parts = concat(
    [
      {
        filename = "10-base.sh"
        content  = file("${local.scripts}/10-base.sh")
      },
      {
        filename = "20-docker.sh"
        content  = templatefile("${local.scripts}/20-docker.sh.tftpl", { ssh_user = var.ssh_user })
      },
    ],
    var.install_minikube ? [
      {
        filename = "30-minikube.sh"
        content = templatefile("${local.scripts}/30-minikube.sh.tftpl", {
          ssh_user           = var.ssh_user
          minikube_version   = var.minikube_version
          kubernetes_version = var.kubernetes_version
          node_count         = var.node_count
          cpus_per_node      = var.cpus_per_node
          memory_per_node_mb = var.memory_per_node_mb
        })
      },
    ] : [],
  )
}

data "cloudinit_config" "this" {
  gzip          = false
  base64_encode = false

  dynamic "part" {
    for_each = local.parts

    content {
      filename     = part.value.filename
      content_type = "text/x-shellscript"
      content      = part.value.content
    }
  }
}
