{
  config,
  lib,
  ...
}:
with lib;
let
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
    services.kanata = {
      enable = true;
      keyboards = {
        "laptop" = {
          # devices = [
          # Replace the paths below with the appropriate device paths for your setup.
          # Use `ls /dev/input/by-path/` to find your keyboard devices.
          #   "/dev/input/by-path/pci-0000:e6:00.1-usb-0:5:1.1-event-kbd"
          #   "/dev/input/by-path/pci-0000:e6:00.1-usbv2-0:5:1.1-event-kbd"
          # ];
          config = ''
             (defsrc
              esc f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
              caps a s d f h j k l ;
            )

            (defvar
              tap-time 150
              hold-time 200
            )

            (defalias
              nav (layer-while-held navigation)
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
              @cw brdn  brup  _    _    _    _   prev  pp  next  mute  vold  volu
              @escnav @a @s @d @f _ @j @k @l @;
            )

            (deflayer navigation
              @cw f1   f2   f3   f4   f5   f6   f7   f8   f9   f10   f11   f12
              _ _ _ _ _ left down up rght _
            )
          '';
          extraDefCfg = "process-unmapped-keys yes";
        };
      };
    };
  };
}
