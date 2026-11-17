# `cloud-init` module

Builds the multipart cloud-init user data that turns a fresh Ubuntu VM into a
Docker host and, optionally, a multi-node minikube cluster. It has no
infrastructure of its own, so the same output is used for OpenStack
instances (`projects/minikube`, `projects/docker`) and for the local LXD VM
(`projects/minikube-lxd`).

```hcl
module "cloud_init" {
  source = "../../modules/cloud-init"

  install_minikube = true
  node_count       = 3
}

# e.g. user_data = module.cloud_init.user_data
```

Scripts in `scripts/` run in filename order:

| Script | Does |
|---|---|
| `10-base.sh` | `apt-get upgrade`, base packages |
| `20-docker.sh.tftpl` | Docker Engine from Docker's apt repository; adds `ssh_user` to the `docker` group |
| `30-minikube.sh.tftpl` | pinned kubectl and minikube with SHA-256 verification, then `minikube start` as `ssh_user` (only if `install_minikube`) |

## Inputs

| Name | Default | Description |
|---|---|---|
| `ssh_user` | `"ubuntu"` | Login user; gets Docker access and runs minikube. |
| `install_minikube` | `true` | `false` = Docker host only. |
| `minikube_version` | `"v1.39.0"` | minikube release. |
| `kubernetes_version` | `"v1.37.0"` | Kubernetes version for the cluster. |
| `node_count` | `3` | 1–5 minikube nodes. |
| `cpus_per_node` | `2` | At least 2. |
| `memory_per_node_mb` | `2200` | At least 1800. |

## Outputs

| Name | Description |
|---|---|
| `user_data` | Multipart user data (plain text, not base64). |
| `part_names` | Script names included, in execution order. |

`tests/cloud_init.tftest.hcl` checks the part selection, that variables reach
the scripts, and the input validation (`terraform init && terraform test`).
