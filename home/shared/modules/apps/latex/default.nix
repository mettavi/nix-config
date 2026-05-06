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
        # recommended add-on packages for LaTeX which have widespread use
        collection-latexrecommended
        # mf command line util for fonts (latex package ifsym)
        metafont
        # provides the fullpage package and others useful for preparing documents
        preprint
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

    xdg.mimeApps.defaultApplications = {
      "text/x-tex" = "texstudio.desktop";
    };
  };
}
