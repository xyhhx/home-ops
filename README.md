<div align="center">

# My Homelab Cluster

Running Kubernetes on Proxmox using Talos Linux

</div>

## Setting up

### Workstation requirements 

This repo expects to be used from a Linux workstation with the following tools installed:

- GNU Make
- OpenTofu 
- talosctl
- kubectl

### Preparing PVE

- **Get a bootable ISO**
  Go to https://factory.talos.dev and get an ISO of the latest version *that has qemu_guest_agent enabled*, save that to your Proxmox host. This is required for the OpenTofu provider to be able to determine that a VM is ready.

- **Preparing a VM template**
  Prepare a VM template that *does not have hard drive, network device, or CDROM drive*, but has a TPM configured. This is because when cloning the template, the provider for some reason overwrites the boot order when using OVMF/UEFI and renders the VM unable to boot

### Bootstrapping

```sh
make tofu init
# This will handle everything!
make cluster 
```

---

### Important Notes

- As of the time of writing this, the published Terraform provider for Proxmox has [a bug](https://github.com/Telmate/terraform-provider-proxmox/issues/1028) where it cannot determine VMs' IP addresses. Since the master branch doesn't have this issue, a workaround is to [build it locally](https://github.com/Telmate/terraform-provider-proxmox/issues/1028#issuecomment-2153659795), which this repo currently expects
