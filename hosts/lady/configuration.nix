{
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.apple-t2
  ];

  users.users.${username} = {
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII1n+RR5GUcqjFh7ypsw5bVOszWnZUa4VltzgK6eYGUv timotheos@salina"
    ];
  };

  nix.settings = {
    # nixos adds cache.nixos.org at the very end so specifying that is not needed.
    # on other systems please use extra-substituters to not overwrite that.

    # NB: Using this binary cache will cause Nix to not rebuild the kernel,
    # so long as non-default options like crash dumping have not been enabled.
    substituters = [ "https://cache.soopy.moe" ];
    trusted-substituters = [ "https://cache.soopy.moe" ]; # to allow building as a non-trusted user
    trusted-public-keys = [ "cache.soopy.moe-1:0RZVsQeR+GOh0VQI9rvnHz55nVXkFardDqfm4+afjPo=" ];
  };

  hardware = {
    # copy Apple Broadcom (brcm) firmware for WiFi and bluetooth
    firmware = [
      (pkgs.stdenvNoCC.mkDerivation (final: {
        name = "bcrm-firmware";
        src = ./firmware/brcm;
        installPhase = ''
          mkdir -p $out/lib/firmware/brcm
          cp ${final.src}/* "$out/lib/firmware/brcm"
        '';
      }))
    ];
    graphics = {
      extraPackages = with pkgs; [
        # unfortunately this driver is deprecated with several security vulnerabilities
        # intel-media-sdk # for Quick Sync Video (QSV) on Intel Iris + G7 iGPU on host mack
        intel-compute-runtime-legacy1 # Intel Graphics Compute Runtime oneAPI Level Zero and OpenCL with support for Gen8, Gen9 and Gen11 GPUs
      ];
    };
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

  # the installation process is allowed to modify EFI boot variables
  # (enabling this is not recommended on T2 macs)
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot";

  # this is required to set up the refind module
  boot.loader.grub.enable = false;
  # TODO: Check on status (replace refind with systemd-boot until https://github.com/NixOS/nixpkgs/pull/453874 is fixed)
  boot.loader.systemd-boot.enable = true;
  # boot.loader.refind = {
  #   enable = true;
  #   efiInstallAsRemovable = true;
  #   extraConfig = # bash
  #     ''
  #       # remove BIOS entries on T2 mac
  #       scanfor internal,external,optical,manual
  #       # hide debug text for OS other than mac
  #       use_graphics_for osx,linux,windows,grub
  #       # prevent the use of NVRAM on T2 mac
  #       use_nvram false
  #     '';
  #   maxGenerations = 10;
  # };

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  ######## SYSTEM SERVICES ##########
  #
  services = {
    xserver = {
      # don't install Xserver
      enable = false;
      xkb = {
        # This might still be used by Wayland
        layout = "us";
        variant = "mac";
      };
    };
  };

  console = {
    useXkbConfig = true; # use xkb.options in tty.
  };

  # TODO: Remove this disabled workaround if multiple tests do not resurface this error
  # Workaround the annoying `Failed to start Network Manager Wait Online` error on switch.
  # https://github.com/NixOS/nixpkgs/issues/180175
  # systemd.services.NetworkManager-wait-online.enable = false;

  # SYSTEM MODULES SETTINGS
  mettavi = {
    system = {
      gnome.enable = true;
      shell = {
        kanata.enable = true;
      };
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
      stateVersion = "25.11";
    };
    mettavi = {
      apps = {
        firefox.enable = true;
        ghostty.enable = true;
        libreoffice.enable = true;
      };
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "25.11"; # Did you read the comment?

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;
}
