{
  config,
  lib,
  pkgs,
  systemConfig,
  ...
}:
with lib; let
  cfg = config.virtualization-suite;
  virtConfig = systemConfig.virtualization;
  
  # VM creation script
  createVMScript = pkgs.writeShellScript "create-vm" ''
    #!/bin/bash
    
    VM_NAME="$1"
    VM_TYPE="$2"
    MEMORY="$3"
    DISK_SIZE="$4"
    
    if [ -z "$VM_NAME" ] || [ -z "$VM_TYPE" ]; then
        echo "Usage: create-vm <name> <type> [memory] [disk_size]"
        echo "Types: win7, kali-cli, ubuntu"
        exit 1
    fi
    
    MEMORY=''${MEMORY:-2048}
    DISK_SIZE=''${DISK_SIZE:-20G}
    
    # Create VM directory
    VM_DIR="$HOME/VMs/$VM_NAME"
    mkdir -p "$VM_DIR"
    
    # Create disk image
    ${pkgs.qemu}/bin/qemu-img create -f qcow2 "$VM_DIR/disk.qcow2" "$DISK_SIZE"
    
    # VM-specific configurations
    case "$VM_TYPE" in
        win7)
            # Windows 7 configuration
            cat > "$VM_DIR/start.sh" << EOF
#!/bin/bash
${pkgs.qemu}/bin/qemu-system-x86_64 \\
    -name "$VM_NAME" \\
    -machine q35 \\
    -cpu host \\
    -smp 2 \\
    -m "$MEMORY" \\
    -drive file="$VM_DIR/disk.qcow2",format=qcow2 \\
    -device virtio-vga-gl \\
    -display gtk,gl=on \\
    -device ich9-intel-hda \\
    -device hda-duplex \\
    -netdev user,id=net0 \\
    -device virtio-net,netdev=net0 \\
    -enable-kvm
EOF
            ;;
        kali-cli)
            # Kali Linux CLI configuration
            cat > "$VM_DIR/start.sh" << EOF
#!/bin/bash
${pkgs.qemu}/bin/qemu-system-x86_64 \\
    -name "$VM_NAME" \\
    -machine q35 \\
    -cpu host \\
    -smp 2 \\
    -m "$MEMORY" \\
    -drive file="$VM_DIR/disk.qcow2",format=qcow2 \\
    -nographic \\
    -netdev user,id=net0 \\
    -device virtio-net,netdev=net0 \\
    -enable-kvm
EOF
            ;;
        ubuntu)
            # Ubuntu configuration
            cat > "$VM_DIR/start.sh" << EOF
#!/bin/bash
${pkgs.qemu}/bin/qemu-system-x86_64 \\
    -name "$VM_NAME" \\
    -machine q35 \\
    -cpu host \\
    -smp 2 \\
    -m "$MEMORY" \\
    -drive file="$VM_DIR/disk.qcow2",format=qcow2 \\
    -device virtio-vga-gl \\
    -display gtk,gl=on \\
    -device intel-hda \\
    -device hda-duplex \\
    -netdev user,id=net0 \\
    -device virtio-net,netdev=net0 \\
    -enable-kvm
EOF
            ;;
    esac
    
    chmod +x "$VM_DIR/start.sh"
    echo "VM $VM_NAME created in $VM_DIR"
    echo "Use $VM_DIR/start.sh to start the VM"
  '';
  
  # VM management script
  vmManagerScript = pkgs.writeShellScript "vm-manager" ''
    #!/bin/bash
    
    VM_DIR="$HOME/VMs"
    
    list_vms() {
        echo "Available VMs:"
        if [ -d "$VM_DIR" ]; then
            ls -1 "$VM_DIR" | while read vm; do
                if [ -f "$VM_DIR/$vm/start.sh" ]; then
                    echo "  - $vm"
                fi
            done
        else
            echo "  No VMs found"
        fi
    }
    
    start_vm() {
        VM_NAME="$1"
        if [ -z "$VM_NAME" ]; then
            echo "Usage: vm-manager start <vm-name>"
            return 1
        fi
        
        if [ -f "$VM_DIR/$VM_NAME/start.sh" ]; then
            echo "Starting VM: $VM_NAME"
            "$VM_DIR/$VM_NAME/start.sh"
        else
            echo "VM $VM_NAME not found"
        fi
    }
    
    case "$1" in
        list|ls)
            list_vms
            ;;
        start)
            start_vm "$2"
            ;;
        create)
            ${createVMScript} "$2" "$3" "$4" "$5"
            ;;
        *)
            echo "Usage: vm-manager <command> [args]"
            echo "Commands:"
            echo "  list, ls          List available VMs"
            echo "  start <vm>        Start a VM"
            echo "  create <name> <type> [memory] [disk_size]"
            echo "                    Create a new VM"
            ;;
    esac
  '';
  
in {
  options.virtualization-suite = {
    enable = mkEnableOption "virtualization with QEMU/KVM";
  };
  
  config = mkIf (cfg.enable && virtConfig.enable) {
    # Enable virtualization
    virtualisation = {
      # QEMU/KVM
      libvirtd = {
        enable = true;
        qemu = {
          package = pkgs.qemu_kvm;
          runAsRoot = false;
          swtpm.enable = true;
          ovmf = {
            enable = true;
            packages = [pkgs.OVMFFull.fd];
          };
        };
      };
      
      # Enable spice USB redirection
      spiceUSBRedirection.enable = true;
    };
    
    # Virtualization packages
    environment.systemPackages = with pkgs; [
      # Core virtualization
      qemu_kvm
      libvirt
      virt-manager
      virt-viewer
      spice
      spice-gtk
      spice-protocol
      win-virtio
      win-spice
      
      # VM management scripts
      (writeShellScriptBin "create-vm" (builtins.readFile createVMScript))
      (writeShellScriptBin "vm-manager" (builtins.readFile vmManagerScript))
      
      # Additional tools
      bridge-utils
      dnsmasq
      
      # For Windows VMs
      ntfs3g
      
      # For network configuration
      iptables
    ];
    
    # Add user to libvirt group
    users.users.${systemConfig.users.primary.username}.extraGroups = [
      "libvirtd"
      "kvm"
    ];
    
    # Enable required kernel modules
    boot.kernelModules = [
      "kvm-amd"    # For AMD processors
      "kvm-intel"  # For Intel processors
      "vfio-pci"
      "vfio"
      "vfio_iommu_type1"
      "vfio_virqfd"
    ];
    
    # Networking for VMs
    networking.firewall = {
      allowedTCPPorts = [];
      # Allow libvirt bridge
      trustedInterfaces = ["virbr0"];
    };
    
    # Sysctl settings for better VM performance
    boot.kernel.sysctl = {
      # Enable IP forwarding for VM networking
      "net.ipv4.ip_forward" = 1;
      
      # Increase file descriptor limit
      "fs.file-max" = 65536;
      
      # VM memory settings
      "vm.swappiness" = 10;
    };
    
    # Create VM directory structure
    systemd.tmpfiles.rules = [
      "d /home/${systemConfig.users.primary.username}/VMs 0755 ${systemConfig.users.primary.username} users -"
      "d /home/${systemConfig.users.primary.username}/VMs/ISOs 0755 ${systemConfig.users.primary.username} users -"
    ];
    
    # Default VM configurations based on config
    systemd.services.setup-default-vms = mkIf (virtConfig.vms != {}) {
      description = "Setup default VMs from configuration";
      after = ["libvirtd.service"];
      wantedBy = ["multi-user.target"];
      serviceConfig = {
        Type = "oneshot";
        User = systemConfig.users.primary.username;
        Group = "users";
      };
      script = let
        vmSetupCommands = concatStringsSep "\n" (mapAttrsToList (vmName: vmConfig:
          if vmConfig.enable then
            "${createVMScript} ${vmName} ${vmConfig.type or "ubuntu"} ${toString (vmConfig.memory or 2048)} ${vmConfig.disk or "20G"}"
          else ""
        ) virtConfig.vms);
      in ''
        cd /home/${systemConfig.users.primary.username}
        ${vmSetupCommands}
      '';
    };
    
    # Libvirt configuration
    systemd.services.libvirtd.preStart = ''
      mkdir -p /var/lib/libvirt/images
      chown root:libvirtd /var/lib/libvirt/images
      chmod 770 /var/lib/libvirt/images
    '';
    
    # Environment variables
    environment.sessionVariables = {
      LIBVIRT_DEFAULT_URI = "qemu:///system";
    };
  };
}