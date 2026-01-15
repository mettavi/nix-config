{
  inputs,
  pkgs,
  username,
  ...
}:
{
  imports = [
    inputs.nixos-hardware.nixosModules.apple-t2
    ./hardware-configuration.nix
    inputs.t2fanrd.nixosModules.t2fanrd
  ];

  users.users.${username} = {
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
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
        name = "brcm-firmware";
        src = ./firmware/brcm;
        installPhase = ''
          mkdir -p $out/lib/firmware/brcm
          cp ${final.src}/* "$out/lib/firmware/brcm"
        '';
      }))
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

  # Enable GuC loading HuC firmware in i915 kernel driver
  # Use low-power encoding with jellyfin to offload the GPU usage with the help of the HuC firmware
  boot.kernelParams = [ "i915.enable_guc=2" ];

  # the installation process is allowed to modify EFI boot variables
  # (enabling this is not recommended on T2 macs)
  boot.loader.efi.canTouchEfiVariables = false;
  boot.loader.efi.efiSysMountPoint = "/boot";

  boot.loader.systemd-boot = {
    enable = true;
    configurationLimit = 10;
  };

  environment.systemPackages = with pkgs; [
    efibootmgr # application to modify the Intel EFI Boot Manager
    lm_sensors # tools for reading hardware sensors
  ];

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.wifi.powersave = false;

  ######## SYSTEM SERVICES ##########
  #
  services = {
    # service to config fans for T2 macs
    t2fanrd = {
      enable = true;
      config = {
        Fan1 = {
          low_temp = 40;
          high_temp = 70;
          speed_curve = "linear";
          always_full_speed = false;
        };
        Fan2 = {
          low_temp = 40;
          high_temp = 70;
          speed_curve = "linear";
          always_full_speed = false;
        };
      };
    };
    xserver = {
      # don't install Xserver by default
      enable = false;
      # gnome only uses xkb config for initial set up, configure in dconf instead
      # see https://discourse.nixos.org/t/strange-xkboptions-behavior-gnome/33535/5
      xkb = {
        # Despite the xserver attribute, this might still be used by Wayland
        model = "macbook78"; # MacBook/MacBook Pro
        layout = "us";
        variant = "mac";
      };
    };
  };

  # setting this to true causes keyboard instability in gnome desktop gui terminal emulators, configure in gnome instead
  console = {
    # need to explicitly disable this setting
    useXkbConfig = false; # use xkb.options in tty.
  };

  # SYSTEM MODULES SETTINGS
  mettavi = {
    system = {
      # use the gnome desktop
      apps = {
        calibre.enable = true;
        libreoffice.enable = true;
        qbittorrent.enable = true;
      };
      desktops = {
        gnome.enable = true;
      };
      devices = {
        intel-chips.enable = true;
        logitech.enable = true;
        touchbar.enable = true;
      };
      shell = {
        kanata.enable = true;
      };
      services = {
        audiobookshelf.enable = true;
        # this also enables the jellyfin module
        jellarr.enable = true;
        networkmanager.enable = true;
        pia-vpn-netmanager.enable = true;
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
      stateVersion = "25.05";
    };
    mettavi = {
      apps = {
        brave.enable = true;
        firefox.enable = true;
        ghostty.enable = true;
      };
    };
    xdg.mimeApps = {
      enable = true;
      /*
        To list all .desktop files, run:
        ls /run/current-system/sw/share/applications # for global packages
        ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
      */
      # See http://discourse.nixos.org/t/how-can-i-configure-the-default-apps-for-gnome/36034
      defaultApplications = {
        # gnome image viewer
        "image/jpeg" = "org.gnome.Loupe.desktop";
        # gnome document viewer
        "application/pdf" = "org.gnome.Evince.desktop";
        "text/html" = "firefox.desktop";
        "x-scheme-handler/http" = "firefox.desktop";
        "x-scheme-handler/https" = "firefox.desktop";
        "x-scheme-handler/about" = "firefox.desktop";
        "x-scheme-handler/unknown" = "firefox.desktop";
      };
    };
  };
  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "25.05"; # Did you read the comment?

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
