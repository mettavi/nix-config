{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  users.users.${username} = {
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPVF5QIYMySsyeuKEjZG97HbbjI28H4GhmmDFUpCgLdj timotheos@lady"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
    ];
  };

  ########## SYSTEM ARCHITECTURE ###########

  # enable in-memory compressed devices and swap space
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # ensure zram is given priority over standard swap
    priority = 100;
  };

  # set the bus ids for the AMD iGPU and nvidia dGPU
  # NB: "pciutils -c lspci -D -d ::03xx" outputs the values in hex, convert them to decimal below
  hardware.nvidia = {
    prime = {
      nvidiaBusId = "PCI:100:0:0";
      amdgpuBusId = "PCI:101:0:0";
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      # only keep 10 generations to prevent the boot partition from running out of space
      configurationLimit = 10;
      # place kernels and generations on a separate, large size partition
      xbootldrMountPoint = "/boot";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  # Use the cachyos kernel for the latest asus g14 kernel patches.
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services = {
    asusd = {
      enable = true;
      # unstable, see https://gitlab.com/asus-linux/asusctl/-/issues/532#note_2879912217
      enableUserService = false;
      # explicitly set to use the package patched locally with an overlay
      package = pkgs.asusctl;
    };
    # this option is already enabled by the asusd module above
    # services.supergfxd.enable = true;
    xserver = {
      # don't install Xserver by default
      enable = false;
      # gnome only uses xkb config for initial set up, configure in dconf instead
      # see https://discourse.nixos.org/t/strange-xkboptions-behavior-gnome/33535/5
      xkb = {
        # Despite the xserver attribute, this might still be used by Wayland
        layout = "us";
        model = "asus_laptop";
      };
    };
  };

  # patch the asusctl package to include "aura" keyboard lighting definitions for this model laptop
  nixpkgs.overlays = [
    (final: prev: {
      asusctl = prev.asusctl.overrideAttrs (oldAttrs: {
        # Append your new patch to the existing list of patches
        patches = (oldAttrs.patches or [ ]) ++ [
          # Path to your patch file (it will be copied to the Nix store)
          ./aura_support_ga403w.patch
        ];
      });
    })
  ];

  # SYSTEM MODULES SETTINGS
  mettavi.system = {
    apps = {
      bitwarden = {
        enable = true;
        backup = true; # this also enables the postfix module
      };
      brave.enable = true;
      calibre = {
        enable = true;
        cal_lib = "${config.users.users.${username}.home}/media/calibre";
      };
      libreoffice.enable = true;
      qbittorrent.enable = true;
    };
    devices = {
      logitech.enable = true;
      nvidia.enable = true;
    };
    desktops = {
      gnome.enable = true;
    };
    services = {
      # this alse enables the podman module
      audiobookshelf = {
        enable = true;
        abs_home = "${config.users.users.${username}.home}/media/audiobooks";
      };
      # enable authentication via face recognition
      howdy.enable = true;
      # this also enables the jellyfin module
      jellarr.enable = true;
      libvirt.enable = true;
      networkmanager.enable = true;
      # uses resolved, dnsmasq and nginx to map localhost IP:port urls to hostnames
      hostdns.enable = true;
      openssh.enable = true;
      pia-vpn-netmanager.enable = true;
    };
    shell = {
      kanata.enable = true;
    };
    userConfig = {
      timotheos.enable = true;
    };
  };

  # (HOST-SPECIFIC) HOME-MANAGER SETTINGS
  home-manager.users.${username} = {
    home = {
      packages = with pkgs; [
        # Simple GPU Profile switcher for ASUS laptops using Supergfxctl
        gnomeExtensions.gpu-supergfxctl-switch
      ];
      sessionVariables = {
        # required for electron apps, which don't read the mimeapps.list file
        DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
      };
      stateVersion = "25.11";
    };
    dconf.settings = {
      # add custom keybindings for ASUS linux utilities
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "ROG Control Center";
        command = "rog-control-center";
        # on the keyboard this is the M4 key
        binding = "Launch1";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Next Power Mode";
        command = "asusctl profile -n";
        # on the keyboard this is Fn-F5
        binding = "Launch4";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Next Aura Mode";
        command = "asusctl led-mode -n";
        # on the keyboard this is Fn-F4
        binding = "Launch3";
      };
      "org/gnome/shell" = {
        # `gnome-extensions list` for a list
        enabled-extensions = [
          "gpu-switcher-supergfxctl@chikobara.github.io"
        ];
      };
    };
    mettavi = {
      apps = {
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
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        # gnome document viewer
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
        "default-web-browser" = [ "firefox.desktop" ];
        "text/html" = [ "firefox.desktop" ];
        "x-scheme-handler/http" = [ "firefox.desktop" ];
        "x-scheme-handler/https" = [ "firefox.desktop" ];
        "x-scheme-handler/about" = [ "firefox.desktop" ];
        "x-scheme-handler/unknown" = [ "firefox.desktop" ];
      };
    };

    # Run the rog-control-center app on system boot so it shows in the system tray (depends on appindicator gnome extension)
    # NB: ensure user lingering is disabled (the default) so the service doesn't run until user login
    # NB: DISABLE THIS SERVICE UNTIL IT IS FIXED
    # systemd.user.services."rog-control-center" = {
    #   Unit = {
    #     Description = "Simple service to start the app on system boot";
    #     # Ensures the service starts after the graphical session (and the appindicator extension) is set up
    #     After = [
    #       "graphical-session-pre.target"
    #       "gnome-shell-wayland.target"
    #     ];
    #     # Requires D-Bus, which is essential for GNOME interaction
    #     Requires = [ "dbus.service" ];
    #   };
    #   Install = {
    #     # the service is automatically started when the user logs in graphically
    #     WantedBy = [ "graphical-session.target" ];
    #   };
    #   Service = {
    #     ExecStart = "${pkgs.asusctl}/bin/rog-control-center";
    #     # Restart = "on-failure";
    #     # RestartSec = 5;
    #   };
    # };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
