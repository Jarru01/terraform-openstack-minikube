# Minikube on OpenStack with Terraform

[![ci](https://github.com/Jarru01/terraform-openstack-minikube/actions/workflows/ci.yml/badge.svg)](https://github.com/Jarru01/terraform-openstack-minikube/actions/workflows/ci.yml)
[![e2e](https://github.com/Jarru01/terraform-openstack-minikube/actions/workflows/e2e.yml/badge.svg)](https://github.com/Jarru01/terraform-openstack-minikube/actions/workflows/e2e.yml)

Terraform that boots an Ubuntu VM on an OpenStack cloud and turns it into a
multi-node [minikube](https://minikube.sigs.k8s.io/) Kubernetes cluster:
security group locked to your IP, your own SSH key, an optional floating IP,
and cloud-init that installs Docker, kubectl and minikube with pinned,
checksum-verified versions.

The provisioning is provider-agnostic. A local variant runs the same
cloud-init on an LXD virtual machine, which is how CI proves on every push
that the scripts really produce a working cluster.

## Repository layout

```text
modules/openstack-vm/    reusable module: secgroup, port, key pair, instance, floating IP
modules/cloud-init/      provisioning scripts and their assembly into user data
projects/minikube/       OpenStack VM + Docker + multi-node minikube
projects/docker/         OpenStack VM + Docker only
projects/minikube-lxd/   local LXD VM + the same provisioning (used by the e2e test)
.github/                 CI (fmt, validate, tests, tflint, shellcheck) and the e2e workflow
```

## Quick start (OpenStack)

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

## Run it locally (LXD)

No OpenStack needed: `projects/minikube-lxd` creates an LXD virtual machine
and hands it the same cloud-init. It needs Linux (or WSL2) with LXD and KVM.

```bash
sudo snap install lxd && sudo lxd init --auto
sudo usermod -aG lxd "$USER"   # then log in again to pick up the group

cd projects/minikube-lxd
terraform init
terraform apply          # returns once the VM is up
./wait-ready.sh          # waits for cloud-init, then requires every node to be Ready
```

Output of the e2e workflow on a GitHub runner
([run](https://github.com/Jarru01/terraform-openstack-minikube/actions/runs/44162659444)):

```text
cloud-init finished after 137s.
All 3 nodes Ready after 142s.
NAME           STATUS   ROLES           AGE   VERSION
minikube       Ready    control-plane   53s   v1.37.0
minikube-m02   Ready    <none>          31s   v1.37.0
minikube-m03   Ready    <none>          15s   v1.37.0
```

`wait-ready.sh` polls with short, retried `lxc exec` calls rather than one
long `cloud-init status --wait`: the LXD agent inside the VM can restart
while cloud-init upgrades packages, which drops a long-running session.

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
- **Provisioning separate from infrastructure.** `modules/cloud-init` knows
  nothing about OpenStack, so the same user data runs on OpenStack and LXD,
  and the LXD run tests what the OpenStack run would execute.
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
| `terraform fmt`, `validate` for every project | CI |
| Module tests: `openstack-vm` against a mocked provider (rule mapping, floating IP switch, input validation); `cloud-init` rendering and validation | CI and locally |
| Same `fmt`, `validate` and module tests with OpenTofu | CI |
| `tflint` (recommended ruleset) | CI |
| cloud-init scripts rendered, then `bash -n` and `shellcheck` | CI |
| **End to end:** LXD VM provisioned with the real cloud-init, all 3 nodes must be `Ready` (about 4 minutes) | e2e workflow, every push and weekly |

Not covered by an automated run: the OpenStack resources against a real
OpenStack API. They are validated and unit-tested against a mocked provider.

```bash
cd modules/openstack-vm && terraform init -backend=false && terraform test
```

## Background

This started as a university cloud-computing lab on the faculty's OpenStack
cloud, and was rebuilt as a tested Terraform project with current minikube
and Kubernetes versions.

## License

[MIT](LICENSE)
