{
  config,
  hostname,
  lib,
  pkgs,
  username,
  ...
}:

{
  imports = [
    # customise the hardware scan config
    # NB: hardware-configuration.nix is auto-generated during install and is imported in the mkNixos function
    ./mount.nix
    ./kernel.nix
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

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services = {
    asusd = {
      enable = true;
      # option is unstable and deprecated, see https://gitlab.com/asus-linux/asusctl/-/issues/532#note_2879912217
      # enableUserService = true;
      # explicitly set to use the package patched locally with an overlay
      package = pkgs.asusctl;
    };
    # do not install this with the asusd module as it is now deprecated
    supergfxd.enable = false;
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

  # AUTOSTARTING THE ROG_CONTROL_CENTRE APP

  # this option is not working reliably, see https://github.com/NixOS/nixpkgs/issues/455932
  # programs.rog-control-center = {
  #   enable = true;
  #   autoStart = true;
  # };
  # so manually define a service instead
  systemd.user.services.rog-control-center = {
    description = "rog-control-center";
    after = [ "graphical-session.target" ];
    partOf = [ "graphical-session.target" ];
    startLimitBurst = 5;
    startLimitIntervalSec = 120;
    wantedBy = [ "graphical-session.target" ];
    serviceConfig = {
      Type = "simple";
      ExecStart = lib.getExe' pkgs.asusctl "rog-control-center";
      Restart = "on-failure";
      RestartSec = 1;
      TimeoutStopSec = 10;
      ExecStartPre = "${pkgs.coreutils}/bin/sleep 5";
    };
  };

  # patch the asusctl package to include "aura" keyboard lighting definitions for this model laptop
  # NB: git clone the repo, add the new lines and then run 'git diff > ../aura_support_ga403w.patch
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
      qbittorrent.enable = true;
    };
    devices = {
      logitech.enable = true;
      nvidia.enable = true;
      # wdssd.enable = true;
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
      btrfs.enable = true;
      # uses resolved, dnsmasq and nginx to map localhost IP:port urls to hostnames
      hostdns.enable = true;
      # enable authentication via face recognition
      howdy.enable = true;
      immich.enable = true;
      # this also enables the jellyfin module
      jellarr.enable = true;
      libvirt.enable = true;
      networkmanager.enable = true;
      openssh.enable = true;
      # also enables the ollama module
      paperless-ngx.enable = true;
      pia-vpn-netmanager.enable = true;
      restic = {
        enable = true;
        jobs = {
          "${hostname}" =
            let
              vol_label = "Share";
            in
            {
              inherit vol_label;
              localConfig = { };
              repo = "/run/media/${username}/${vol_label}";
              volumes = {
                "@adminhome" = {
                  exclusions = [
                    ".Trash-0"
                    ".local/share/Trash"
                    ".npm"
                  ];
                  mount = "/home/${username}";
                  paths = [ "." ];
                };
                "@adminmedia" = {
                  exclusions = [ ".Trash-0" ];
                  mount = "/home/${username}/media";
                  paths = [ "." ];
                };
                "@root" = {
                  exclusions = [
                    ".Trash-0"
                    "/var/backup/postgresql/*.prev.sql"
                  ];
                  mount = "/";
                  paths = [
                    "etc/group"
                    "etc/machine-id"
                    "etc/NetworkManager/system-connections"
                    "etc/passwd"
                    "etc/ssh/ssh_${hostname}_ed25519_key*"
                    "etc/subgid"
                    "var/backup/postgresql"
                    # includes the important /var/lib/nixos
                    "var/lib"
                  ];
                };
                "@roothome" = {
                  exclusions = [
                    ".Trash-0"
                    ".local/share/Trash"
                  ];
                  mount = "/root";
                  paths = [ "." ];
                };
                "@vlpostgres" = {
                  exclusions = [ ".Trash-0" ];
                  mount = "/var/lib/postgresql";
                  paths = [ "." ];
                };
              };
            };
        };
      };
      snapper = {
        enable = true;
        mounts = {
          # The key (e.g., 'adminhome') is just a label for Nix
          adminhome = {
            datadir = "/home/${username}";
            snapsvol = "@adminhome-snaps";
            # You can override specific settings just for adminhome!
            extraConfig = {
              TIMELINE_LIMIT_HOURLY = "24";
            };
          };
          adminmedia = {
            datadir = "/home/${username}/media";
            snapsvol = "@adminmedia-snaps";
          };
          vlpostgres = {
            datadir = "/var/lib/postgresql";
            snapsvol = "@vlpostgres-snaps";
          };
        };
      };
    };
    shell = {
      # see the host-specific keyboard config below
      kanata.enable = true;
    };
    userConfig = {
      timotheos.enable = true;
    };
  };

  # KEYBOARD CONFIG
  services.kanata.keyboards."home-keys" = {
    config = ''
      ;; Remap Copilot key to sysrq
      (defchordsv2
       (lsft lmet f23) ssrq 10 all-released ()
      )
    '';
    extraDefCfg = ''
      ;; disable this until kanata can detect the asus keyboard device again
      ;; linux-dev-names-include (
      ;;  "Asus Keyboard"
      ;;  "Asus WMI hotkeys"
      ;;)
      ;; Required for defchordsv2 (see above)
      concurrent-tap-hold yes
    '';
  };

  # includes system settings (located in system directory)
  mettavi = {
    apps = {
      libreoffice.enable = true;
    };
  };

  # home-manager modules installed for the admin user ON THIS HOST ONLY
  home-manager.users.${username} = {
    mettavi = {
      apps = {
        latex.enable = true;
      };
      shell = {
        nvim-wrap.enable = true;
      };
    };
  };

  # experimental code for mapping the copilot key to sysrq, implemented instead with kanata
  # NB: kept for reference to the keyboard name/code on this host
  # services.udev = {
  #   extraHwdb = ''
  # choose one of the following two lines to identify the keyboard
  #     evdev:name:Asus Keyboard:*
  #     evdev:input:b0003v0B05p19B6e0110*
  #      KEYBOARD_KEY_70072=sysrq # original KEY_F23 (copilot key)
  #   '';
  # };

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
