terraform {
  required_version = ">= 1.6.0"

  required_providers {
    openstack = {
      source  = "terraform-provider-openstack/openstack"
      version = "~> 3.4"
    }
    cloudinit = {
      source  = "hashicorp/cloudinit"
      version = "~> 2.4"
    }
    http = {
      source  = "hashicorp/http"
      version = "~> 3.6"
    }
  }
}

# Credentials are never part of the configuration. The provider reads them
# from the clouds.yaml entry named in var.cloud / OS_CLOUD, or from the OS_*
# variables of an OpenStack RC file.
provider "openstack" {
  cloud = var.cloud
}
