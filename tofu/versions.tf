terraform {
  required_providers {
    proxmox = {
      source = "terraform.local/local/proxmox"
      version = "3.0.1-rc3"
    }
    random = {
      source  = "registry.opentofu.org/hashicorp/random"
      version = "3.5.1"
    }
    tls = {
      source  = "registry.opentofu.org/hashicorp/tls"
      version = "4.0.4"
    }
    talos = {
      source  = "registry.opentofu.org/siderolabs/talos"
      version = "0.5.0"
    }
  }
}
