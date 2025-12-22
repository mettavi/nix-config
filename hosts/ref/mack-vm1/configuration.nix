# WAS: host "oona"
{
  modulesPath,
  username,
  ...
}:
{
  imports = [
    # imports for initial install with nixos-anywhere and disko
    # subsequently the disko config will configure fstab
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./hardware-configuration.nix
    ./disk-config.nix
  ];

  ########## IMPORTANT SETTINGS ###########

  # SETUP INITIAL ACCESS
  users.users.${username} = {
    # authorize remote login using ssh key(s)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
    ];
  };

  # this host is a vmware guest running on darwin host "mack"
  # enable VMWare guest support
  virtualisation.vmware.guest.enable = true;

  # setup a file share from the host to the guest
  # NB: also requires manual set up on the darwin host
  fileSystems."/mnt/mack/${username}" = {
    # this folder must be exported on the host beforehand
    device = ".host:/${username}";
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    mountPoint = "/mnt/mack/${username}";
    options = [
      "umask=22"
      "uid=1000"
      "gid=100"
      "allow_other"
      "defaults"
      "auto_unmount"
      # prevents emergency mode upon misconfiguration
      "nofail"
    ];
  };

  # enable automatic login for the user.
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "${username}";
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

  # Use systemd for the bootloader
  boot.loader = {
    # the installation process is allowed to modify EFI boot variables
    efi.canTouchEfiVariables = true;
    # enable the systemd-boot EFI boot manager
    systemd-boot.enable = true;
  };

  services = {
    xserver = {
      # Enable the X11 windowing system.
      enable = true;
      # Select the login manager
      displayManager = {
        lightdm = {
          enable = true;
        };
      };
      desktopManager = {
        xfce = {
          enable = true;
        };
      };
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "mac";
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

  ######## SYSTEM SERVICES ##########

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
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

  # (HOST-SPECIFIC) HOME-MANAGER SETTINGS
  home-manager.users.${username} = {
    home = {
      file = {
        # create a desktop shortcut to the desktop file created under xdgDesktopEntries below
        # ".local/state/nix/profiles/home-manager/home-path/share/applications/mack-timotheos.desktop";
        # config.home-manager.users.${username}.home.profileDirectory
        # "${pkgs.mack-timotheos.desktop}/share/applications/mack-timotheos.desktop";
        "Desktop/mack-timotheos.desktop".text = # bash
          ''
            [Desktop Entry]
            Comment=Home directory for timotheos on host mack
            Exec=exo-open --working-directory /mnt/mack/timotheos --launch FileManager
            Icon=folder
            Name=mack-timotheos
            Terminal=false
            Type=Application
            Version=1.5
          '';
      };
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "25.05";
    };
    mettavi = {
      apps = {
        ghostty.enable = true;
      };
      desktop = {
        # configure the XFCE desktop
        xfce.enable = true;
      };
    };
    programs = {
      firefox = {
        enable = true;
      };
    };
    xdg.desktopEntries = {
      # add a desktop shortcut to the host share
      mack-timotheos = {
        name = "mack-timotheos";
        comment = "Home directory for timotheos on host mack";
        icon = "folder";
        type = "Application";
        # this is an XFCE-specific command
        exec = "exo-open --working-directory /mnt/mack/timotheos --launch FileManager";
      };
    };
  };
}
