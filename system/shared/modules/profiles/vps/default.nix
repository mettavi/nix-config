{
  config,
  lib,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.profiles.vps;
in
{
  options.mettavi.system.profiles.vps = with lib.types; {
    enable = mkOption {
      type = bool;
      default = false;
      description = "A profile for a virtual private/cloud server";
    };
    isQemuGuest = mkOption {
      type = bool;
      default = true;
      description = "Whether the VPS is a qemu guest vm";
    };
    useDHCP = mkOption {
      type = bool;
      default = false;
      description = "Whether to use DHCP on the VPS host";
    };
    devName = mkOption {
      type = str;
      default = "sda";
      description = "The device name (/dev/<devName>)";
    };
    netInterface = mkOption {
      type = str;
      description = "The name of the main network interface on the system";
    };
    ip4 = {
      addr = mkOption {
        type = str;
        description = "The static IP (v4) of the network interface";
      };
      prefix = mkOption {
        type = (
          lib.types.enum [
            16
            24
            32
          ]
        );
        default = 24;
        description = "The prefix of the IP (v4)";
      };
      gateway = mkOption {
        type = str;
        description = "The default gateway IP (v4)";
      };
    };
    ip6 = {
      addr = mkOption {
        type = str;
        description = "The static IP (v6) of the network interface";
      };
      prefix = mkOption {
        type = ints.unsigned;
        description = "The prefix of the IP (v6)";
      };
      gateway = mkOption {
        type = str;
        description = "The default gateway IP (v6)";
      };
    };
  };

  config = mkIf cfg.enable {
    # Ensure kernel output goes to both the web VNC display (eg. in the VPS panel terminal) and the serial console
    boot.kernelParams = [
      "console=tty1"
      "console=ttyS0,115200"
    ];

    boot.kernel.sysctl = {
      # 10 is recommended for servers (default is 60)
      "vm.swappiness" = 10;
    };

    # set up a hyrbid boot, with BIOS and a UEFI fallback
    # many VPS VMs default to a legacy BIOS mode
    boot.loader = {
      grub = {
        # grub works on both BIOS and UEFI
        enable = true;
        device = "/dev/${cfg.devName}"; # Install GRUB to the MBR
        efiSupport = true; # Support UEFI just in case
        # Crucial for VPS: Installs bootloader to a fallback path
        # so it boots even if NVRAM variables are reset by the host.
        efiInstallAsRemovable = true;
      };
      # systemd-boot does not support BIOS
      systemd-boot.enable = false;
    };

    # Set your routing (FIND THESE IN THE VPS)
    networking.defaultGateway = "${cfg.ip4.gateway}";
    networking.defaultGateway6 = {
      address = "${cfg.ip6.gateway}";
      interface = "${cfg.netInterface}";
    };

    # Explicitly configure your network interface
    networking.interfaces.${cfg.netInterface} = {
      useDHCP = cfg.useDHCP;
      ipv4.addresses = [
        {
          address = "${cfg.ip4.addr}";
          prefixLength = cfg.ip4.prefix; # Verify in VPS (usually 24 or 32)
        }
      ];
      ipv6.addresses = [
        {
          address = "${cfg.ip6.addr}";
          prefixLength = cfg.ip6.prefix; # Verify in VPS
        }
      ];
    };

    # Set DNS resolvers
    networking.nameservers = [
      "8.8.8.8"
      "1.1.1.1"
    ];

    # Many VPS services use static networking (default to static)
    networking.useDHCP = cfg.useDHCP;

    programs = {
      # Enable Mosh (MObile SHell) server side and auto-configure firewall rules
      mosh = {
        enable = true;
        openFirewall = true; # opens UDP port range 60000-61000
      };
    };

    services.openssh = {
      settings = {
        # options to harden openssh, especially for servers
        # forbid the use of ssh password authentication
        PasswordAuthentication = false;
      };
    };

    # enable the qemu guest agent if required
    services.qemuGuest.enable = cfg.isQemuGuest;

    # keep terminal sessions alive on the server
    home-manager.users.${username} = {
      mettavi.shell.tmux.enable = true;
    };
  };
}
