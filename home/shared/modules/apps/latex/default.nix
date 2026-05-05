{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.latex;
  tex = (
    pkgs.texliveBasic.withPackages (
      ps: with ps; [
        collection-latexrecommended
      ]
    )
  );
in
{
  options.mettavi.apps.latex = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure latex packages and a tex editor";
    };
  };

  config = mkIf cfg.enable {
    home.packages = with pkgs; [
      tex
      texstudio
    ];
  };
}
