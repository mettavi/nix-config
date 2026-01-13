{
  config,
  lib,
  nix_repo,
  pkgs,
  username,
  ...
}:
with lib;
let
  hostname = config.networking.hostName;
  cfg = config.mettavi.system.shell.kanata;
in
{
  options.mettavi.system.shell.kanata = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install kanata, a tool to improve keyboard usability with advanced customization, on NixOS";
    };
  };

  config = mkIf cfg.enable {
    # set this explicitly to bypass the first-run bug, even though it is already set in the module
    # see https://github.com/NixOS/nixpkgs/issues/317282 for details
    hardware.uinput.enable = true;

    services.kanata = {
      enable = true;
      keyboards = {
        "Asus-G14-${hostname}" = {
          # An empty list, the default value, lets kanata detect which input devices are keyboards and intercept them all.
          # Setting this option is necessary to automatically assign different configs to different hosts/devices
          # NOTE: This option is not working on host oona under nixos (even as root with a minimal config - requires more testing)
          # The workaround is to use "linux-dev-names-include" in option extraDefCfg instead
          devices = [
            # Replace the paths below with the appropriate device paths for your setup.
            # Use `ls /dev/input/by-path/` to find your keyboard devices.
            #   "/dev/input/by-path/pci-0000:e6:00.1-usb-0:5:1.1-event-kbd"
            #   "/dev/input/by-path/pci-0000:e6:00.1-usbv2-0:5:1.1-event-kbd"
            # Prefer `ls /dev/input/by-id/` if possible as this is more stable
            # ASUS G24 GA403WR laptop keyboard (currently not working)
            # "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8910_-hidraw"
            # "/dev/hidraw0"
          ];
          config = ''
             (defsrc
              esc
              caps a s d f h j k l ;
            )

            (defvar
              tap-time 150
              hold-time 200
            )

            (defalias
              nav (layer-while-held navigation)
              ;; spc and other keys will terminate the caps-lock, so typing a sentence will require the key to be reused
              cw (caps-word 5000)
              escnav (tap-hold 100 100 esc @nav)
              ;; trigger a tap when rolling within the timeout (unless second key is released first)
              ;; don't trigger hold for keys from same side ("bilateral combinations")
              a (tap-hold-except-keys $tap-time $hold-time a lalt (q w e r t a s d f g z x c v b))
              s (tap-hold-except-keys $tap-time $hold-time s lmet (q w e r t a s d f g z x c v b))
              d (tap-hold-except-keys $tap-time $hold-time d lsft (q w e r t a s d f g z x c v b))
              f (tap-hold-except-keys $tap-time $hold-time f lctl (q w e r t a s d f g z x c v b))
              j (tap-hold-except-keys $tap-time $hold-time j rctl (y u i o p h j k l ; n m , . /))
              k (tap-hold-except-keys $tap-time $hold-time k rsft (y u i o p h j k l ; n m , . /))
              l (tap-hold-except-keys $tap-time $hold-time l rmet (y u i o p h j k l ; n m , . /))
              ; (tap-hold-except-keys $tap-time $hold-time ; ralt (y u i o p h j k l ; n m , . /))
            )

            (deflayer base
              @cw
              @escnav @a @s @d @f _ @j @k @l @;
            )

            (deflayer navigation
              @cw
              _ _ _ _ _ left down up rght _
            )
          '';
          extraDefCfg = optionalString ("${hostname}" == "oona") ''
            linux-dev-names-include (
              "Asus Keyboard"
            )
            process-unmapped-keys yes
          '';
        };
      };
    };
    # required for preventing permissions errors when connecting to keyboard devices using the services.kanata.devices option
    # services.udev.extraRules = ''
    #   KERNEL=="uinput", MODE="0660", GROUP="uinput", OPTIONS+="static_node=uinput"
    #   SUBSYSTEM=="hidraw", ATTRS{idVendor}=="0b05", ATTRS{idProduct}=="19b6", GROUP="uinput", MODE="0660"
    #   # KERNEL=="hidraw0", SUBSYSTEM=="hidraw", GROUP="uinput", MODE="0660"
    # '';
    # environment.systemPackages = with pkgs; [ kanata ];

    # THIS IS A MANUAL SYSTEMD CONFIGURATION FOR TESTING
    systemd.services.kanata-Asus-G14 = {
      enable = false;
      unitConfig = {
        Description = "Kanata keyboard remapper";
        Documentation = "https://github.com/jtroo/kanata";
        Wants = "modprobe@uinput.service";
        After = "modprobe@uinput.service";
      };
      serviceConfig = {
        Type = "simple";
        # User = "kanata";
        Environment = [ "PATH=/run/current-system/sw/bin:/etc/profiles/per-user/${username}/bin" ];
        ExecStart = "${pkgs.kanata}/bin/kanata --quiet --cfg ${
          config.users.users.${username}.home
        }/${nix_repo}/system/nixos/modules/shell/kanata/kanata.lsp";
        Restart = "no";

        # REMOVE ALL HARDENING OPTIONS TO TEST WITH A MINIMAL CONFIG
        # Security
        # CapabilityBoundingSet = "";
        # DeviceAllow = [
        #   "/dev/uinput rw"
        #   "char-input"
        #   "/dev/stdin"
        #   "/dev/input/by-id/usb-ITE_Tech._Inc._ITE_Device_8910_-hidraw r"
        #   "/dev/hidraw0 r"
        # ];
        # DevicePolicy = "strict";
        # PrivateDevices = true;
        # BindPaths = [ "/dev/uinput" ];
        # BindReadOnlyPaths = [
        #   "/dev/stdin"
        #   "/dev/input/"
        #   "${config.users.users.${username}.home}/${nix_repo}/"
        # ];
        # InaccessiblePaths = "/dev/shm";
        # LockPersonality = true;
        # NoNewPrivileges = true;
        # PrivateTmp = true;
        # PrivateNetwork = true;
        # PrivateUsers = true;
        # The following (ProtectClock) can not be enabled, otherwise Kanata can not open /dev/uinput.
        # More hardening would require to explicitly list allowed system calls.
        #ProtectClock=true
        # ProtectHome = true;
        # ProtectHostname = true;
        # ProtectKernelTunables = true;
        # ProtectKernelModules = true;
        # ProtectKernelLogs = true;
        # ProtectSystem = "strict";
        # ProtectControlGroups = true;
        # Allow only on AddressFamily and then deny it to effectively deny everything
        # RestrictAddressFamilies = [
        #   "AF_AX25"
        #   "~AF_AX25"
        # ];
        # RestrictNamespaces = true;
        # RuntimeDirectory = "Asus-G14";
        # SystemCallArchitectures = "native";
        # SystemCallErrorNumber = "EPERM";
        # SystemCallFilter = [
        #   "@system-service"
        #   "~@privileged"
        #   "~@resources"
        # ];
        # RemoveIPC = true;
        # IPAddressDeny = "any";
        # RestrictSUIDSGID = true;
        # RestrictRealtime = true;
        # MemoryDenyWriteExecute = true;
        # UMask = "0077";
      };
      wantedBy = [ "multi-user.target" ];
    };
    # users.users.root.extraGroups = [
    #   "uinput"
    #   "input"
    # ];
  };
}
