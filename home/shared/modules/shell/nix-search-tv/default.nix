{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.nix-search-tv;
  ns = pkgs.writeShellScriptBin "ns" (builtins.readFile "${pkgs.nix-search-tv.src}/nixpkgs.sh");
in
{
  options.mettavi.shell.nix-search-tv = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure the nix-search-tv search tool";
    };
  };

  config = mkIf cfg.enable {
    programs.nix-search-tv = {
      enable = true;
      # Configuration written to $XDG_CONFIG_HOME/nix-search-tv/config.json
      settings = { };
    };
    home.packages = [ ns ];
  };
}
