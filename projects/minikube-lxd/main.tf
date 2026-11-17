# Local variant: the same cloud-init provisioning as projects/minikube, but on
# an LXD virtual machine instead of an OpenStack instance. `terraform apply`
# only succeeds once provisioning has finished and every node reports Ready,
# so a successful apply is an end-to-end test of the cloud-init scripts.

module "cloud_init" {
  source = "../../modules/cloud-init"

  ssh_user           = "ubuntu"
  minikube_version   = var.minikube_version
  kubernetes_version = var.kubernetes_version
  node_count         = var.node_count
  cpus_per_node      = var.cpus_per_node
  memory_per_node_mb = var.memory_per_node_mb
}

locals {
  # Run as the login user, whose kubeconfig minikube wrote.
  as_ubuntu = ["runuser", "-l", "ubuntu", "-c"]
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

  # Commands run through the LXD agent once the VM is up, in key order.
  wait_for {
    type = "agent"
  }

  execs = {
    "10-wait-for-cloud-init" = {
      # Exit code 1 means cloud-init failed; 2 ("degraded") only flags
      # warnings, so the node check below is the real gate.
      command       = ["/bin/sh", "-c", "cloud-init status --wait --long; rc=$?; [ $rc -ne 1 ]"]
      fail_on_error = true
    }
    "20-nodes-ready" = {
      command = concat(local.as_ubuntu, [join(" && ", [
        "kubectl wait --for=condition=Ready nodes --all --timeout=10m",
        "test \"$(kubectl get nodes --no-headers | wc -l)\" -eq ${var.node_count}",
      ])])
      fail_on_error = true
    }
    "30-get-nodes" = {
      command       = concat(local.as_ubuntu, ["kubectl get nodes -o wide"])
      record_output = true
    }
  }

  timeouts = {
    create = var.ready_timeout
  }
}
