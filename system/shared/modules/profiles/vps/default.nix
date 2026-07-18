{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.profiles.vps;
in
{
  options.mettavi.system.profiles.vps = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for a virtual private/cloud server";
    };
    useDHCP = mkOption {
      type = types.bool;
      default = false;
      description = "Whether the use DHCP on the VPS host";
    };
    netInterface = mkOption {
      type = types.str;
      description = "The name of the main network interface on the system";
    };
  };

  config = mkIf cfg.enable {
    # Ensure kernel output goes to both the web VNC display (eg. in the hostinger panel) and the serial console
    boot.kernelParams = [
      "console=tty1"
      "console=ttyS0,115200"
    ];

    # set up a hyrbid boot, with BIOS and a UEFI fallback
    # many VPS VMs default to a legacy BIOS mode
    boot.loader = {
      grub = {
        # grub works on both BIOS and UEFI
        enable = true;
        device = "/dev/sda"; # Install GRUB to the MBR
        efiSupport = true; # Support UEFI just in case
        # Crucial for VPS: Installs bootloader to a fallback path
        # so it boots even if NVRAM variables are reset by the host.
        efiInstallAsRemovable = true;
      };
      # systemd-boot does not support BIOS
      systemd-boot.enable = false;
    };

    services.openssh =
      if pkgs.stdenv.isLinux then
        {
          settings = {
            # options to harden openssh, especially for servers
            # forbid the use of ssh password authentication
            PasswordAuthentication = false;
          };
        }
      else
        {
          extraConfig = ''
            PasswordAuthentication no
          '';
        };

    # Many VPS services use static networking
    networking.useDHCP = cfg.useDHCP;

    # Explicitly configure your network interface
    networking.interfaces.${cfg.netInterface} = {
      useDHCP = cfg.useDHCP;
      ipv4.addresses = [
        {
          address = "187.127.105.244";
          prefixLength = 24; # Verify in Hostinger panel (usually 24 or 32)
        }
      ];
      ipv6.addresses = [
        {
          address = "2a02:4780:5e:616::1";
          prefixLength = 48; # Verify in Hostinger panel
        }
      ];
    };

    # Set your routing (FIND THESE IN THE HOSTINGER PANEL)
    networking.defaultGateway = "187.127.105.254";
    networking.defaultGateway6 = {
      address = "2a02:4780:5e::1";
      interface = "${cfg.netInterface}";
    };

    # Set DNS resolvers
    networking.nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];

    systemd.tmpfiles.rules = [ "L+ /var/lib/qemu/firmware - - - - ${pkgs.qemu}/share/qemu/firmware" ];

  };
}
