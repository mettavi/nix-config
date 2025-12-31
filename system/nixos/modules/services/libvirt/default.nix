{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.libvirt;
in
{
  options.mettavi.system.services.libvirt = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure virtualisation using the kms, qemu and libvirt stack";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      dnsmasq # VM networking
    ];
    # a UI for managing virtual machines in libvirt
    programs.virt-manager.enable = true;
    # enable UEFI firmware support in Virt-Manager, Libvirt, Gnome-Boxes etc, see https://wiki.nixos.org/wiki/QEMU
    systemd.tmpfiles.rules = [
      "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu_kvm}/share/qemu/firmware"
    ];

    users.users.${username}.extraGroups = [ "libvirtd" ];

    # the module now installs OVMF automatically
    # Open Virtual Machine Firmware (OVMF) is a UEFI firmware implementation for virtual machines
    # that makes features like secure boot available
    virtualisation = {
      libvirtd = {
        enable = true;
        # Generic and open source machine emulator and virtualizer
        qemu = {
          package = pkgs.qemu_kvm;
          # use software trusted platform module (SWTPM) to create an emulated TPM chip (not required for secure boot)
          # install pkgs.swtpm system-wide for use in virt-manager
          swtpm.enable = true;
          # support sharing of folders with the guest
          vhostUserPackages = with pkgs; [
            virtiofsd # vhost-user virtio-fs device backend
          ];
        };
      };
      # Enable USB redirection
      spiceUSBRedirection.enable = true;
    };
    home-manager.users.${username} = {
      # add a default hypervisor to bypass the initial prompt
      dconf.settings = {
        "org/virt-manager/virt-manager/connections" = {
          autoconnect = [ "qemu:///system" ];
          uris = [ "qemu:///system" ];
        };
      };
      # required under wayland
      home.pointerCursor = {
        gtk.enable = true;
        # Style neutral scalable cursor theme
        package = pkgs.vanilla-dmz;
        name = "Vanilla-DMZ";
      };
    };
  };
}
