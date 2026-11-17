# `openstack-vm` module

One OpenStack instance with its own security group, Neutron port, SSH key
pair and an optional floating IP.

```hcl
module "vm" {
  source = "../../modules/openstack-vm"

  name             = "demo"
  image_name       = "Ubuntu 24.04"
  flavor_name      = "m1.small"
  network_name     = "private"
  floating_ip_pool = "public" # optional
  ssh_public_key   = file("~/.ssh/id_ed25519.pub")
  user_data        = file("cloud-init.yaml")

  ingress_rules = [
    { description = "SSH", protocol = "tcp", port_min = 22, cidr = "203.0.113.0/24" },
    { description = "ping", protocol = "icmp", cidr = "203.0.113.0/24" },
  ]
}
```

## Inputs

| Name | Type | Default | Description |
|---|---|---|---|
| `name` | `string` | — | Base name for all resources (lowercase, digits, dashes). |
| `image_name` | `string` | — | Glance image name; the most recent match is used. |
| `flavor_name` | `string` | — | Nova flavor name. |
| `network_name` | `string` | — | Network for the instance port. |
| `floating_ip_pool` | `string` | `null` | External network to allocate a floating IP from. |
| `ssh_public_key` | `string` | — | OpenSSH public key. Only the public half reaches Terraform state. |
| `ingress_rules` | `list(object)` | `[]` | `description`, `protocol` (`tcp`/`udp`/`icmp`), `cidr`, optional `port_min`/`port_max`. TCP/UDP to `0.0.0.0/0` is rejected. |
| `user_data` | `string` | `null` | cloud-init user data. Changes are ignored after creation; use `-replace` to re-provision. |
| `ssh_user` | `string` | `"ubuntu"` | Login user, used for the `ssh_command` output. |
| `metadata` | `map(string)` | `{}` | Instance metadata. |

## Outputs

| Name | Description |
|---|---|
| `instance_id` | Nova instance ID. |
| `fixed_ip` | Address on `network_name`. |
| `public_ip` | Floating IP if allocated, otherwise the fixed IP. |
| `security_group_id` | For adding rules from the caller. |
| `ssh_command` | `ssh <user>@<public_ip>`. |

## Tests

`tests/openstack_vm.tftest.hcl` runs against a mocked provider, so no cloud
is needed:

```bash
terraform init -backend=false
terraform test
```

It covers rule mapping (single ports, ranges, ICMP, IPv4/IPv6), the
floating-IP switch and the input validations.
