{
  modulesPath,
  username,
  ...
}:
{
  imports = [
    # imports for initial install with nixos-anywhere and disko
    # subsequently the disko config will configure fstab
    # NB: hardware-configuration.nix is auto-generated during install and is imported in the mkNixos function
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disko-config.nix
    ./hardware-configuration.nix
  ];

  ########## IMPORTANT SETTINGS ###########

  # SETUP INITIAL ACCESS
  # set up root access to prevent initial password problems for the primary user
  users.users.root = {
    # hashedPassword = "$y$j9T$kD6Saa3hxt3U5YCkHGtBp/$ybiLXiDq1f6EitKgQTPB8Nyw2BzvI2QOI0IlR.TKyf1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
    ];
  };

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
    ];
  };

  ########## SYSTEM ARCHITECTURE ###########

  # lower the unprivileged port floor so rootless containers can bind under port 1024
  boot.kernel.sysctl."net.ipv4.ip_unprivileged_port_start" = 0;

  # enable in-memory compressed devices and swap space
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "26.05";

  # SYSTEM MODULES SETTINGS
  mettavi = {
    system = {
      devices = {
        # create and mount btrfs subvolumes using disko
        disko-btrfs.enable = true;
      };
      profiles = {
        # hostinger vps (eg. ssh hardening)
        vps = {
          enable = true;
          netInterface = "eth0";
          ip4 = {
            addr = "72.62.193.208";
            prefix = 24;
            gateway = "72.62.193.254";
          };
          ip6 = {
            addr = "2a02:4780:5e:a648::1";
            prefix = 48;
            gateway = "2a02:4780:5e::1";
          };
        };
      };
      # enable system users
      userConfig = {
        timotheos.enable = true;
      };
    };
  };

  # (HOST-SPECIFIC) HOME-MANAGER SETTINGS
  home-manager.users.${username} = {
    home = {
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "26.05";
    };
  };
}
