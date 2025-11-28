{
  pkgs,
  username,
  ...
}:
{
  imports = [
    ./hardware-configuration.nix
  ];

  ########## IMPORTANT SETTINGS ###########

  # SETUP INITIAL ACCESS
  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
    ];
  };

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
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

  # SYSTEM MODULES SETTINGS
  mettavi = {
    system = {
      # enable system users
      userConfig = {
        timotheos = {
          enable = true;
        };
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "25.05";

  # (HOST-SPECIFIC) HOME-MANAGER SETTINGS
  home-manager.users.${username} = {
    home = {
      packages = with pkgs; [
        gparted # graphical disk partitioning tool
      ];
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "25.05";
    };
    mettavi = {
      apps = {
        ghostty.enable = true;
      };
    };
  };
}
