{
  config,
  lib,
  ...
}:
let
  cfg = config.mettavi.apps.mpv;
in
{
  options.mettavi.apps.mpv = {
    enable = lib.mkEnableOption "Install and set up the mpv general-purpose media player";
  };

  config = lib.mkIf cfg.enable {
    home.shellAliases = {
      # launch mpv using the nvidia dGPU (usually not necessary)
      mpvg = "nvidia-offload mpv --profile=dgpu";
    };

    programs.mpv = {
      enable = true;
      # Input configuration written to $XDG_CONFIG_HOME/mpv/input.conf
      bindings = {
        "Alt+0" = "set window-scale 0.5";
        WHEEL_DOWN = "seek -10";
        WHEEL_UP = "seek 10";
      };
      # Configuration written to $XDG_CONFIG_HOME/mpv/mpv.conf
      config = {
        vo = "gpu-next";
        gpu-context = "wayland";
        # use AMD iGPU by default
        hwdec = "vaapi";
      };
      profiles = {
        # prefer vulkan when using the nvidia dGPU
        dgpu = {
          gpu-api = "vulkan";
          gpu-context = "waylandvk";
          hwdec = "nvdec";
        };
      };
    };
  };
}
