{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.ollama;
in
{
  options.mettavi.system.services.ollama = {
    enable = mkEnableOption "Install and set up the ollama LLM service";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      package = mkIf (config.mettavi.system.devices.nvidia) pkgs.ollama-cuda; # nividia GPU acceleration
      home = "/var/lib/ollama";
      host = "127.0.0.1";
      # Optional: preload models, see https://ollama.com/library
      loadModels = [
      ];
      models = "${config.services.ollama.home}/models";
      openFirewall = false;
      port = 11434;
      # remove any models not declared in the loadModels option
      syncModels = false;
      # defaults to the "DynamicUser"
      user = "${username}";
    };
  };
}
