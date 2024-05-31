output "control_plane_ids" {
  value = {
    for k, v in proxmox_vm_qemu.talos-control-plane-node : k => v.id
  }
}

output "worker_ids" {
  value = {
    for k, v in proxmox_vm_qemu.talos-work-plane-node : k => v.id
  }
}

