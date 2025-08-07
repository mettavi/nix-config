{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.profiles.mbp;
in
{
  options.nyx.profiles.mbp = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for my macbookpro, currently my daily OS";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      obsidian
      zoom-us # video conferencing applications
    ];
  };
}
