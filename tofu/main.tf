resource "proxmox_vm_qemu" "talos-control-plane-node" {
  count = var.control_plane_nodes_count

  name        = "talos-control-plane-${count.index + 1}"
  vmid        = var.pve_vmid_start + count.index
  clone       = var.pve_talos_template_name
  target_node = var.pve_node
  tags        = var.pve_tags

  agent         = 1
  agent_timeout = var.pve_agent_timeout 

  memory  = var.total_control_plane_memory / var.control_plane_nodes_count 
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

resource "proxmox_vm_qemu" "talos-work-plane-node" {
  count = var.worker_nodes_count

  name        = "talos-work-plane-${count.index + 1}"
  vmid        = var.pve_vmid_start + var.control_plane_nodes_count + count.index
  clone       = var.pve_talos_template_name
  target_node = var.pve_node
  tags        = var.pve_tags

  agent         = 1
  agent_timeout = var.pve_agent_timeout

  memory  = var.total_work_plane_memory / var.worker_nodes_count 
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
