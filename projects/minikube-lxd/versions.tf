terraform {
  required_version = ">= 1.6.0"

  required_providers {
    lxd = {
      source  = "terraform-lxd/lxd"
      version = "~> 3.1"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.4"
    }
  }
}

# Talks to the local LXD daemon over its unix socket; no credentials needed.
# (Image remotes such as "ubuntu:" are built in and need no remote block.)
provider "lxd" {
  remote {
    name    = "local"
    address = "unix://"
  }
}
