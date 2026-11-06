terraform {
  required_version = ">= 1.5.0"

  required_providers {
    local = {
      source  = "hashicorp/local"
      version = "~> 2.9"
    }
  }
}

locals {
  inventory = {
    all = {
      children = {
        switches = {
          hosts = {
            for name, device in var.devices :
            name => {
              ansible_host = device.ip
            }
            if device.group == "switches"
          }
        }

        routers = {
          hosts = {
            for name, device in var.devices :
            name => {
              ansible_host = device.ip
            }
            if device.group == "routers"
          }
        }
      }
    }
  }
}

resource "local_file" "ansible_inventory" {
  filename = "${path.module}/../ansible/inventory/hosts.yml"
  content  = yamlencode(local.inventory)
}