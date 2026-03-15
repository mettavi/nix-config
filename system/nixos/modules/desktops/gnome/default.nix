{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.desktops.gnome;
in
{
  options.mettavi.system.desktops.gnome = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Enable and configure the gnome desktop environment on the system";
    };
  };

  imports = [
    ./gsconnect.nix # sub-module to install the gsconnect extension
    ./xdg.nix # configure xdg portals for gnome
  ];

  config = mkIf cfg.enable {
    environment = {
      gnome.excludePackages = with pkgs; [
        gnome-console # terminal emulator for the GNOME desktop
        gnome-tour
        epiphany # web broswer (aka "Gnome Web")
      ];
      systemPackages =
        (with pkgs; [
          nautilus-python # Python bindings for the Nautilus Extension API
        ])
        ++ (with pkgs.gst_all_1; [
          # GSTREAMER PLUGINS
          gst-plugins-base
          gst-plugins-good
          gst-plugins-bad
          gst-plugins-ugly
          gst-libav # FFmpeg plugin for GStreamer
          gst-vaapi # Set of VAAPI GStreamer Plug-ins
        ]);
      variables = {
        # Allow apps such as Gnome Files (Nautilus) to detect gstreamer plugins
        GST_PLUGIN_PATH_1_0 = [ "/run/current-system/sw/lib/gstreamer-1.0" ];
      };
    };

    services = {
      # install GNOME using wayland
      displayManager.gdm.enable = lib.mkDefault true;
      desktopManager.gnome.enable = true;
      gnome = {
        # allow to install GNOME Shell extensions from a web browser
        gnome-browser-connector.enable = true;
        # authorise file sharing with other devices
        gnome-user-share.enable = true;
      };
    };
    users.users.root = {
      # add apps for root to use for troubleshooting (as the eqivalent gnome builtin apps have been removed system wide)
      packages = with pkgs; [
        firefox
        ghostty
      ];
    };

    home-manager.users.${username} =
      { config, nixosConfig, ... }:
      {
        home.packages =
          (with pkgs; [
            celluloid # GTK frontend for the mpv video player
            dconf-editor # GSettings editor for GNOME
            gnome-extension-manager # Desktop app for managing GNOME shell extensions
            gnome-tweaks # Tool to customize advanced GNOME 3 options
            switcheroo # Gnome app for converting (and resizing) images between different formats (uses imagemagick)
            wl-clipboard # command line copy/paste utilities for Wayland
          ])
          ++ (with pkgs.gnomeExtensions; [
            appindicator # Adds AppIndicator, KStatusNotifierItem and legacy tray icons support to the Shell.
            power-profile-indicator-2 # Add current power profile in panel's system icons.
          ]);
        # Use `dconf watch /` to track stateful changes you are doing, then set them here
        dconf.settings = {
          # organise the apps menu into folders
          "org/gnome/desktop/app-folders" = {
            folder-children = [
              "Utilities"
              "System"
              "Gnome Tools"
              "Nix"
            ];
          };
          "org/gnome/desktop/app-folders/folders/Gnome Tools" = {
            name = "Gnome Tools";
            apps = [
              "com.mattjakeman.ExtensionManager.desktop"
              "org.gnome.tweaks.desktop"
              "ca.desrt.dconf-editor.desktop"
            ];
            translate = false;
          };
          "org/gnome/desktop/app-folders/folders/Nix" = {
            name = "Nix";
            apps = [
              "nixos-manual.desktop"
              "home-manager-manual.desktop"
            ];
            translate = false;
          };
          "org/gnome/desktop/interface" = {
            # set the system to dark mode
            color-scheme = "prefer-dark";
            # Setting this seems deprecated (set color-scheme as above instead),
            # and also breaks dark mode in LibreOffice, see:
            # https://superuser.com/questions/1885361/libreoffice-ignores-appearance-mode-but-observes-the-gtk-theme-environment-vari
            # gtk-theme = "Adwaita-dark";
          };
          "org/gnome/shell" = {
            disable-user-extensions = false;
            # auto-enable installed extensions (run `gnome-extensions list` for a list)
            enabled-extensions = [
              "appindicatorsupport@rgcjonas.gmail.com"
              "power-profile@fthx"
            ];
          };
          "org/gnome/desktop/wm/keybindings" = {
            # workaround for problem with the ALT-F2 default for the Gnome run dialog
            panel-run-dialog = [
              "<Alt>F2" # this is the default
              "<Alt>S" # this is a workaround for the keyboard on host lady
            ];
          };
          # "org/gnome/desktop/peripherals/keyboard" = {
          # delay = lib.hm.gvariant.mkUint32 175;
          # disable to check
          # repeat = false;
          # repeat-interval = lib.hm.gvariant.mkUint32 18;
          # };
        };
        gtk = {
          enable = true;
          theme = {
            name = "Adwaita-dark";
            package = pkgs.gnome-themes-extra;
          };
          iconTheme = {
            name = "Adwaita";
            package = pkgs.adwaita-icon-theme;
          };
          cursorTheme = {
            name = "Adwaita";
            size = 24;
            package = pkgs.adwaita-icon-theme;
          };
          # DISABLE THIS SETTING TO PREVENT THE ERROR:
          # "Using GtkSettings:gtk-application-prefer-dark-theme with libadwaita is unsupported.
          # Please use AdwStyleManager:color-scheme instead""
          # Use the extraConfig setting instead (see below)
          # colorScheme = "dark";
          gtk3 = {
            # configure bookmarks in nautilus/files left-menu
            bookmarks =
              optionals nixosConfig.mettavi.system.services.paperless-ngx.enable [
                "file://${nixosConfig.services.paperless.consumptionDir} paperless"
              ]
              ++ [
                "file://${config.xdg.userDirs.documents}"
                "file://${config.xdg.userDirs.download}"
                "file://${config.xdg.userDirs.music}"
                "file://${config.xdg.userDirs.pictures}"
                "file://${config.xdg.userDirs.videos}"
              ];
            # Use extraConfig instead of colorScheme to avoid gtk-interface-color-scheme=2 bug
            extraConfig.gtk-application-prefer-dark-theme = 1;
          };
          # GTK 4: Disable theme to prevent broken gtk.css import workaround
          # Dark mode is handled via dconf color-scheme = "prefer-dark" above
          # See: https://github.com/nix-community/home-manager/issues/8232
          gtk4.theme = null;
        };
        qt = {
          enable = true;
          # give Qt apps a similar look and feel to the adwaita-dark theme used by Gnome
          # See https://wiki.nixos.org/wiki/GNOME#GNOME_Qt_integration
          platformTheme.name = "adwaita";
          style.name = "adwaita-dark";
        };
      };
  };
}
