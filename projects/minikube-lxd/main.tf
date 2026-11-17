# Local variant: the same cloud-init provisioning as projects/minikube, but on
# an LXD virtual machine instead of an OpenStack instance.
#
# `terraform apply` returns once the VM is up and its LXD agent responds;
# provisioning continues inside the VM. `./wait-ready.sh` then waits for
# cloud-init and checks that every minikube node is Ready (CI does the same).

module "cloud_init" {
  source = "../../modules/cloud-init"

  ssh_user           = "ubuntu"
  minikube_version   = var.minikube_version
  kubernetes_version = var.kubernetes_version
  node_count         = var.node_count
  cpus_per_node      = var.cpus_per_node
  memory_per_node_mb = var.memory_per_node_mb
}

resource "lxd_instance" "this" {
  name  = var.name
  image = var.image
  type  = "virtual-machine" # a VM, not a container: minikube runs Docker in Docker

  config = {
    "cloud-init.user-data" = module.cloud_init.user_data
    "limits.cpu"           = tostring(var.vm_cpus)
    "limits.memory"        = var.vm_memory
  }

  device {
    name = "root"
    type = "disk"
    properties = {
      path = "/"
      pool = var.storage_pool
      size = var.disk_size
    }
  }

  wait_for {
    type = "agent"
  }

  timeouts = {
    create = "10m"
  }
}
