{
  modulesPath,
  pkgs,
  username,
  ...
}:
{
  imports = [
    # imports for initial install with nixos-anywhere and disko
    # subsequently the disko config will configure fstab
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
    ./hardware-configuration.nix
  ];

  # install the ghostty terminfo (which is missing from current versions of terminfo) for ssh sessions to host salina
  environment.systemPackages = with pkgs; [ ghostty.terminfo ];

  ########## IMPORTANT SETTINGS ###########

  # SETUP INITIAL ACCESS
  # set up root access to prevent initial password problems for the primary user
  users.users.root = {
    hashedPassword = "$y$j9T$kD6Saa3hxt3U5YCkHGtBp/$ybiLXiDq1f6EitKgQTPB8Nyw2BzvI2QOI0IlR.TKyf1";
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
    ];
  };

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
    ];
  };

  ########## SYSTEM ARCHITECTURE ###########

  # enable in-memory compressed devices and swap space
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
  };

  boot.kernel.sysctl = {
    # default is 60
    "vm.swappiness" = 90;
  };

  # Use systemd for the bootloader
  boot.loader = {
    # the installation process is allowed to modify EFI boot variables
    efi.canTouchEfiVariables = true;
    # enable the systemd-boot EFI boot manager
    systemd-boot.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "25.05";

  # SYSTEM MODULES SETTINGS
  nyx = {
    profiles = {
      # oracle cloud vps (eg. ssh hardening)
      vps = {
        enable = true;
      };
    };
    system = {
      # enable system users
      userConfig = {
        timotheos = {
          enable = true;
        };
      };
    };
  };

  # (HOST-SPECIFIC) HOME-MANAGER SETTINGS
  home-manager.users.${username} = {
    home = {
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "25.05";
    };
  };
}
