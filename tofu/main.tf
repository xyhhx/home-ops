resource "random_id" "cluster_id" {
  byte_length = 32
}

resource "talos_machine_secrets" "this" {}

data "talos_machine_configuration" "controlplane" {
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${proxmox_vm_qemu.talos_control_plane_node[0].default_ipv4_address}:6443"
  machine_type     = "controlplane"
  machine_secrets  = talos_machine_secrets.this.machine_secrets 
	config_patches   = concat(
		[templatefile("${path.module}/templates/installer.yaml.tmpl", {
			install_image = var.talos_install_image
		})]
	)
}

resource "proxmox_vm_qemu" "talos_control_plane_node" {
  count = var.control_plane_nodes_count

  name        = "talos-control-plane-${count.index + 1}"
  vmid        = var.pve_vmid_start + count.index
  clone       = var.pve_talos_template_name
  target_node = var.pve_node
  tags        = var.pve_tags

  agent         = 1
  agent_timeout = var.pve_agent_timeout 

  memory  = floor(var.total_control_plane_memory / var.control_plane_nodes_count)
  cores   = var.control_plane_cores
  sockets = var.control_plane_sockets
  scsihw  = "virtio-scsi-single"
  onboot  = true

  network {
		bridge   = var.pve_bridge 
    tag      = var.pve_vlan_tag
    model    = "virtio"
    firewall = false 
  }

  disks {
    ide {
      ide0 {
        cdrom {
          iso = var.pve_talos_iso 
        }
      }
    }
    
    scsi {
      scsi0 {
        disk {
          size       = var.pve_boot_disk_size 
          storage    = var.pve_boot_disk_storage
          emulatessd = true
          discard    = true
        }
      }
    }
  }
}

data "talos_client_configuration" "this" {
  cluster_name         = var.talos_cluster_name
  client_configuration = talos_machine_secrets.this.client_configuration 
  endpoints            = [for i,v in proxmox_vm_qemu.talos_control_plane_node: v.default_ipv4_address]
  nodes                = [for i,v in proxmox_vm_qemu.talos_control_plane_node: v.default_ipv4_address]
}

resource "talos_machine_configuration_apply" "controlplane" {
  for_each = {for i,v in proxmox_vm_qemu.talos_control_plane_node: i => v} 

  client_configuration        = talos_machine_secrets.this.client_configuration 
  machine_configuration_input = data.talos_machine_configuration.controlplane.machine_configuration
  node                        = each.value.default_ipv4_address
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
      }
    }),
  ]
}

resource "talos_machine_bootstrap" "controlplane" {
  for_each = {for i,v in proxmox_vm_qemu.talos_control_plane_node: i => v} 
  depends_on = [
    talos_machine_configuration_apply.controlplane
  ]
  node                 = each.value.default_ipv4_address
  client_configuration = talos_machine_secrets.this.client_configuration 
}

data "talos_machine_configuration" "worker" {
  cluster_name     = var.talos_cluster_name
  cluster_endpoint = "https://${proxmox_vm_qemu.talos_control_plane_node[0].default_ipv4_address}:6443"
  machine_type     = "worker"
  machine_secrets  = talos_machine_secrets.this.machine_secrets 
	depends_on			 = [proxmox_vm_qemu.talos_control_plane_node[0]]
	config_patches   		 = concat(
		[templatefile("${path.module}/templates/installer.yaml.tmpl", {
			install_image = var.talos_install_image
		})]
	)
}

resource "proxmox_vm_qemu" "talos_worker_node" {
  count = var.worker_nodes_count

  name        = "talos-work-plane-${count.index + 1}"
  vmid        = var.pve_vmid_start + var.control_plane_nodes_count + count.index
  clone       = var.pve_talos_template_name
  target_node = var.pve_node
  tags        = var.pve_tags

  agent         = 1
  agent_timeout = var.pve_agent_timeout

  memory  = floor(var.total_work_plane_memory / var.worker_nodes_count)
  cores   = var.worker_cores
  sockets = var.worker_sockets
  scsihw  = "virtio-scsi-single"
  onboot  = true

  network {
		bridge   = var.pve_bridge 
    tag      = var.pve_vlan_tag
    model    = "virtio"
    firewall = false 
  }

  disks {
    ide {
      ide0 {
        cdrom {
          iso = var.pve_talos_iso 
        }
      }
    }
    
    scsi {
      scsi0 {
        disk {
          size       = var.pve_boot_disk_size 
          storage    = var.pve_boot_disk_storage
          emulatessd = true
          discard    = true
        }
      }

      scsi1 {
        passthrough {
          file = tolist(var.pve_passthrough_disks)[count.index]
        }
      }
    }
  }
}

resource "talos_machine_configuration_apply" "worker" {
  for_each = {for i,v in proxmox_vm_qemu.talos_worker_node: i => v} 

  client_configuration        = talos_machine_secrets.this.client_configuration
  machine_configuration_input = data.talos_machine_configuration.worker.machine_configuration
  node                        = each.value.default_ipv4_address
  config_patches = [
    yamlencode({
      machine = {
        install = {
          disk = "/dev/sda"
        }
      }
    }),
  ]
}

data "talos_cluster_kubeconfig" "this" {
  depends_on           = [talos_machine_bootstrap.controlplane]
  client_configuration = talos_machine_secrets.this.client_configuration
  node                 = proxmox_vm_qemu.talos_control_plane_node[0].default_ipv4_address 
}

