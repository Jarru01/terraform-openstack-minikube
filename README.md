# Minikube on OpenStack with Terraform

[![ci](https://github.com/Jarru01/terraform-openstack-minikube/actions/workflows/ci.yml/badge.svg)](https://github.com/Jarru01/terraform-openstack-minikube/actions/workflows/ci.yml)

Terraform that boots an Ubuntu VM on any OpenStack cloud and turns it into a
multi-node [minikube](https://minikube.sigs.k8s.io/) Kubernetes cluster:
security group locked to your IP, your own SSH key, an optional floating IP,
and cloud-init that installs Docker, kubectl and minikube with pinned,
checksum-verified versions.

A second project reuses the same module for a plain Docker host.

## Repository layout

```text
modules/openstack-vm/   reusable module: secgroup, port, key pair, instance, floating IP
  tests/                terraform test suite with a mocked OpenStack provider
projects/minikube/      root config: VM + Docker + multi-node minikube
projects/docker/        root config: VM + Docker only
cloud-init/             provisioning scripts, run in filename order
.github/                CI: fmt, validate, unit tests, tflint, shellcheck
```

## Quick start

Requirements: Terraform ≥ 1.6 or OpenTofu ≥ 1.6, an OpenStack project, an Ubuntu
22.04/24.04 image, and an SSH key pair (`ssh-keygen -t ed25519`).

```bash
# 1. Credentials: a clouds.yaml entry ...
export OS_CLOUD=mycloud
#    ... or the RC file downloaded from Horizon
# source ./myproject-openrc.sh

# 2. Configure
cd projects/minikube
cp terraform.tfvars.example terraform.tfvars   # set image, flavor, network

# 3. Deploy
terraform init
terraform apply

# 4. Wait for provisioning and check the cluster
$(terraform output -raw ssh_command) 'cloud-init status --wait && kubectl get nodes'
```

Example output (illustrative, with the default 3 nodes):

```text
NAME           STATUS   ROLES           AGE   VERSION
minikube       Ready    control-plane   2m    v1.37.0
minikube-m02   Ready    <none>          90s   v1.37.0
minikube-m03   Ready    <none>          60s   v1.37.0
```

Tear down with `terraform destroy`.

### Main inputs (`projects/minikube`)

| Variable | Default | Notes |
|---|---|---|
| `image_name`, `flavor_name`, `network_name` | — | Names as shown by `openstack image/flavor/network list`. |
| `floating_ip_pool` | `null` | Set when `network_name` is not reachable from your machine. |
| `admin_cidrs` | `[]` | Who may SSH in. Empty = your current public IPv4 `/32`, detected at plan time. |
| `ssh_public_key_path` | `~/.ssh/id_ed25519.pub` | Validated to exist before any API call. |
| `minikube_version` / `kubernetes_version` | `v1.39.0` / `v1.37.0` | Kubernetes defaults to what the pinned minikube release ships with. |
| `node_count`, `cpus_per_node`, `memory_per_node_mb` | `3`, `2`, `2200` | `plan` warns if the flavor is too small for this shape. |

## Design notes

- **No secrets in code or state.** The provider reads credentials from
  `clouds.yaml` or `OS_*` variables. The key pair is created from *your*
  public key, so no private key is ever generated into Terraform state.
- **Least-privilege network access.** The only ingress is what the root
  config asks for: SSH and ICMP from `admin_cidrs`. The module refuses
  TCP/UDP rules open to `0.0.0.0/0`.
- **Reproducible provisioning.** minikube and kubectl versions are pinned and
  their SHA-256 checksums are verified before install. Docker comes from
  Docker's signed apt repository. Scripts run with `set -euo pipefail`, so a
  failed step shows up in `cloud-init status` instead of being skipped.
- **Explicit port.** The module creates the Neutron port itself, so the
  security group lives on the port and a floating IP can attach to it
  regardless of how the instance was booted.
- **No surprise rebuilds.** `user_data` changes are ignored after creation;
  re-provision deliberately with `terraform apply -replace=module.vm.openstack_compute_instance_v2.this`.
- **Sizing check.** A `check` block compares the flavor's RAM and vCPUs with
  `node_count × memory_per_node_mb` and warns during `plan`.

The three "nodes" are Docker containers on one VM (minikube's docker
driver). That is ideal for learning multi-node scheduling, taints and
DaemonSets on a single small VM, but it is not a highly available cluster.

## Testing

| Check | Where |
|---|---|
| `terraform fmt`, `validate` for both projects | CI |
| Module unit tests (`terraform test`, mocked provider: rule mapping, floating IP switch, input validation) | CI and locally |
| Same `fmt`, `validate` and unit tests with OpenTofu | CI |
| `tflint` (recommended ruleset) | CI |
| cloud-init templates rendered, then `bash -n` and `shellcheck` | CI |

```bash
cd modules/openstack-vm && terraform init -backend=false && terraform test
```

## Background

This started as a university cloud-computing lab on the faculty's OpenStack
cloud, and was rebuilt as a provider-agnostic, tested module with current
minikube and Kubernetes versions.

## License

[MIT](LICENSE)
