{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
with lib;
let
  emailSecrets.sopsFile = "${secrets_path}/secrets/apps/email.yaml";
in
{
  imports = [
    # customise the hardware scan config
    # NB: hardware-configuration.nix is auto-generated during install and is imported in the mkNixos function
    ./mount.nix
    ./kernel.nix
  ];

  time.timeZone = lib.mkForce "America/Los_Angeles";

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
      # TODO: Support has now been added,
      # see https://github.com/OpenGamingCollective/asusctl/commit/8bf37ed1b2f3da34b2a6047267958f365ce8e131
      # This fix will ship with the next version 6.3.8
      asusctl = prev.asusctl.overrideAttrs (oldAttrs: {
        # Append your new patch to the existing list of patches
        patches = (oldAttrs.patches or [ ]) ++ [
          # Path to your patch file (it will be copied to the Nix store)
          ./aura_support_ga403w.patch
        ];
      });
      # TODO: Remove this overlay when v6.0.8 hits nixos-unstable branch
      # install a newer version for bugfix https://github.com/gramps-project/gramps/pull/2204
      # (and other updates added to v6.0.8)
      gramps =
        let
          # 1. Compile the exact version of the missing Python library
          my-gedcomx = final.python3Packages.buildPythonPackage rec {
            pname = "gedcomx_v1";
            version = "1.0.24";
            src = final.fetchPypi {
              inherit pname version;
              hash = "sha256-C8wKaNY3aG8PAVqN/b/417KeBw5SSj62sbKqhHbjx9o=";
            };
            pyproject = true;
            build-system = [ final.python3Packages.setuptools ];
            propagatedBuildInputs = [ final.python3Packages.requests ];
            doCheck = false;
          };

        in
        prev.gramps.overrideAttrs (oldAttrs: {
          version = "6.0.8";
          src = prev.fetchFromGitHub {
            owner = "gramps-project";
            repo = "gramps";
            rev = "v6.0.8";
            hash = "sha256-Kq+QyhghBmUzl+ooCYSl2yNMvrBDnQS6Zg3nBI1jbRo=";
          };

          # 2. Append extra modules to the core pythonPath wrapper target
          # This safely extends the path without breaking baseline GTK/GDK layers
          pythonPath = (oldAttrs.pythonPath or [ ]) ++ [
            final.python3Packages.requests
            final.python3Packages.pygobject3
            my-gedcomx
          ];

          # 3. Retain your original map window canvas variables
          qtWrapperArgs = (oldAttrs.qtWrapperArgs or [ ]) ++ [
            "--prefix"
            "GI_TYPELIB_PATH"
            ":"
            "${final.osm-gps-map}/lib/girepository-1.0:${final.gtk3}/lib/girepository-1.0"
            "--prefix"
            "GSETTINGS_SCHEMAS_PATH"
            ":"
            "${final.gtk3}/share/gsettings-schemas/${final.gtk3.name}"
          ];
        });
    })
  ];

  # enable appimage apps on this host
  programs.appimage = {
    # enable appimage-run wrapper script for executing appimages
    enable = true;
    # enable binfmt registration to run appimages via appimage-run seamlessly
    binfmt = true;
    # wrap additional dependencies into the appimage-run wrapper script
    package = pkgs.appimage-run.override {
      extraPkgs =
        pkgs: with pkgs; [
          libepoxy
          sqlite
        ];
    };
  };

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
      liboffice-lite.enable = true;
      qbittorrent.enable = true;
    };
    devices = {
      logitech.enable = true;
      nvidia.enable = true;
      t7ssd.enable = true;
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
      paperless-ngx.enable = false;
      paperless-redux.enable = true;
      pia-vpn-netmanager.enable = true;
      restic = {
        enable = true;
        jobs = {
          "${hostname}" =
            let
              vol_label = "backup";
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
                    "var/backup/luks"
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
      libreoffice.enable = false;
    };
  };

  # home-manager modules installed for the admin user ON THIS HOST ONLY
  home-manager.users.${username} = {
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
        command = "asusctl profile next";
        # on the main keyboard this is Fn-F5
        binding = "Launch4";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Next Aura Mode";
        command = "asusctl leds next";
        # on the main keyboard this is Fn-F4
        binding = "Launch3";
      };
      "org/gnome/shell" = {
        # `gnome-extensions list` for a list
        enabled-extensions = [
          "gpu-switcher-supergfxctl@chikobara.github.io"
        ];
      };
    };
    home = {
      packages = with pkgs; [
        # Simple GPU Profile switcher for ASUS laptops using Supergfxctl
        gnomeExtensions.gpu-supergfxctl-switch
        goldendict-ng # Advanced multi-dictionary lookup program
        gramps # Genealogy software
        # these two are required for the PersonFS plugin in gramps
        gobject-introspection
        osm-gps-map
        linpkgs.tipitaka_pali_reader
      ];
      sessionVariables = {
        # required for electron apps, which don't read the mimeapps.list file
        DEFAULT_BROWSER = "${pkgs.firefox}/bin/firefox";
      };
      stateVersion = "25.11";
    };

    # define sops secrets for email accounts used specifically on this host
    sops.secrets = {
      "users/${username}/email/${inputs.secrets.email.burner}" = emailSecrets;
    };

    # create a symlink to the paperless genealogy media directory for gramps (not possible with home.file)
    systemd.user.tmpfiles.rules = [
      # type path mode user group (expiry) (argument)
      "L+ ${
        config.users.users.${username}.home
      }/media/gramps/allen/documents - - - - /var/lib/paperless/personal/media/documents/archive/Genealogy Record"
    ];

    xdg.mimeApps = {
      enable = true;
      /*
        To list all .desktop files, run:
        ls /run/current-system/sw/share/applications # for global packages
        ls /etc/profiles/per-user/$(id -n -u)/share/applications # for user packages
        To find out the mimetype of a file, run:
        file --mime-type filename
      */
      # See http://discourse.nixos.org/t/how-can-i-configure-the-default-apps-for-gnome/36034
      defaultApplications = {
        # gnome image viewer
        "image/jpeg" = [ "org.gnome.Loupe.desktop" ];
        # do not add jpg, as it is not a valid mimetype
        # see https://stackoverflow.com/questions/33692835/is-the-mime-type-image-jpg-the-same-as-image-jpeg
        # "image/jpg" = [ "org.gnome.Loupe.desktop" ];
        # gnome document viewer
        "application/pdf" = [ "org.gnome.Evince.desktop" ];
      };
    };
    mettavi = {
      apps = {
        anki.enable = true;
        firefox.enable = true;
        ghostty.enable = true;
        latex.enable = true;
        obsidian.enable = true;
        thunderbird =
          let
            burner = inputs.secrets.email.burner;
            monk = inputs.secrets.email.monk;
            personal = inputs.secrets.email.personal;
            # NB: 1. leave "accountFilters" unassigned in extraEmailAccounts to use all filters
            # 2. the default "flavor" is "gmail.com"
          in
          {
            enable = true;
            accountsOrder = [
              personal
              monk
              burner
            ];
            extraEmailAccounts = {
              ${monk} = {
                accountFilters = [
                  "tagGH"
                ];
                address = monk;
                aliases = [ personal ];
              };
              ${burner} = {
                accountFilters = [
                ];
                address = burner;
              };
            };
          };
      };
      shell = {
        bash.enable = true;
        nh.enable = true;
        nvim-wrap.enable = true;
        tmux.enable = true;
        yazi.enable = true;
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
