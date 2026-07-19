{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.services.ollama;
  currentVersion = builtins.fromJSON config.system.nixos.release;
  modelsAttr = if currentVersion <= 26.05 then "models" else "modelsDir";
in
{
  options.mettavi.system.services.ollama = {
    enable = mkEnableOption "Install and set up the ollama LLM service";
  };

  config = mkIf cfg.enable {
    services.ollama = {
      enable = true;
      environmentVariables = {
        # OLLAMA_DEBUG = "1";
      };
      package = mkIf (config.mettavi.system.devices.nvidia.enable) pkgs.ollama-cuda; # nividia GPU acceleration
      home = "/var/lib/ollama";
      # bind to all local interfaces, allowing podman bridges to access LLM endpoints
      host = "0.0.0.0";
      # Optional: preload models, see https://ollama.com/library
      # loadModels = [
      # ];
      ${modelsAttr} = "${config.services.ollama.home}/models";
      # for conectivity with podman container networks
      openFirewall = true;
      port = 11434;
      # remove any models not declared in the loadModels option
      syncModels = false;
      # defaults to the "DynamicUser"
      # user = "${username}";
    };
  };
}
