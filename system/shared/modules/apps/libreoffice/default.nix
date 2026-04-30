# code borrowed from:
# https://github.com/somasis/puter/blob/963795efe0991ffa32ffcc78a5397f90d3afdba2/users/somasis/desktop/documents/writing.nix
{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  # gtk version (the kdeIntegration variable defaults to false)
  lo = pkgs.libreoffice-fresh;
  # cfg = config.mettavi.system.apps.libreoffice;
  cfg = config.mettavi.apps.libreoffice;

  loExtensions = [
    # <https://extensions.libreoffice.org/en/extensions/show/27416>
    # (pkgs.fetchurl {
    #   url = "https://extensions.libreoffice.org/assets/downloads/90/1676301090/TemplateChanger-L-2.0.1.oxt";
    #   hash = "sha256-i1+Huqsq2fYstUS4HevqpNc0/1zKRBQONMz6PB9HYh4=";
    # })

    # <https://extensions.libreoffice.org/en/extensions/show/27347>
    # (pkgs.fetchurl {
    #   url = "https://extensions.libreoffice.org/assets/downloads/73/1672894181/open_recent_doc.oxt";
    #   hash = "sha256-4ZZlqJKPuEw/9Sg7vyjLHERFL9yqWamtwAvldJkgFTg=";
    # })

    # <https://extensions.libreoffice.org/en/extensions/show/english-dictionaries>
    # (pkgs.fetchurl {
    #   url = "https://extensions.libreoffice.org/assets/downloads/41/1680302696/dict-en-20230401_lo.oxt";
    #   hash = "sha256-TXRr6BgGAQ4xKDY19OtowN6i4MdINS2BEtq2zLJDkZ0=";
    # })

    # <https://extensions.libreoffice.org/en/extensions/show/languagetool>
    # (pkgs.fetchurl {
    #   url = "https://writingtool.org/writingtool/releases/WritingTool-1.0.oxt";
    #   hash = "sha256-fACV86IIsMMmMnNMfgtePt9bMvRaDICSyLKhVQUXNKw=";
    # })
  ]
  ++
    lib.optional config.home-manager.users.${username}.mettavi.apps.zotero.enable
      "${pkgs.zotero}/lib/integration/libreoffice/Zotero_LibreOffice_Integration.oxt";

  loInstallExtensions =
    assert (builtins.isList loExtensions);
    pkgs.writeShellScript "libreoffice-install-extensions" ''
      PATH=${
        lib.makeBinPath [
          pkgs.gnugrep
          pkgs.coreutils
          lo
        ]
      }
      ${lib.toShellVar "exts" loExtensions}

      ext_is_installed() {
          for installed_ext in "''${installed_exts[@]}"; do
              installed_ext_basename=''${installed_ext##*/}
              [[ "$1" == "$installed_ext_basename" ]] && return 0
          done
          return 1
      }

      mapfile -t installed_exts < <(unopkg list | grep '^  URL:' | cut -d ' ' -f4-)

      for ext in "''${exts[@]}"; do
          ext_is_installed "$(basename "$ext")" || unopkg add -v -s "$ext"
      done
    '';

  loWrapperBeforeCommands = pkgs.writeShellScript "libreoffice-before-execute" ''
    if [[ "$(pgrep -c -u "''${USER:=$(id -un)}" 'soffice\.bin')" -eq 0 ]]; then
        ${loInstallExtensions} || :
    fi
  '';

  loWrapped = lo.override {
    extraMakeWrapperArgs = [
      "--add-flags '--nologo'"
      "--run ${loWrapperBeforeCommands}"
    ];
  };
in
{
  options.mettavi.apps.libreoffice = {
    enable = lib.mkEnableOption "Install and set up the libreoffice suite";
  };

  config = lib.mkIf cfg.enable {
    home-manager.users.${username} =
      { nixosConfig, ... }:
      {
        dconf.settings = lib.mkIf nixosConfig.mettavi.system.desktops.gnome.enable {
          # organise the apps menu into folders
          "org/gnome/desktop/app-folders" = {
            folder-children = [
              "LibreOffice"
            ];
          };
          "org/gnome/desktop/app-folders/folders/LibreOffice" = {
            name = "LibreOffice";
            apps = [
              "startcenter.desktop"
              "writer.desktop"
              "impress.desktop"
              "calc.desktop"
              "math.desktop"
              "base.desktop"
              "draw.desktop"
            ];
            translate = false;
          };
        };
        # environment.systemPackages = with pkgs; [
        home.packages = with pkgs; [
          loWrapped
          hunspell
          hunspellDicts.en_AU
          hunspellDicts.en_US
          hyphenDicts.en_US
          # MS fonts
          corefonts
          vista-fonts
        ];

        home.sessionVariables = {
          PYTHONPATH = "${lo}/lib/libreoffice/program";
          URE_BOOTSTRAP = "vnd.sun.star.pathname:${lo}/lib/libreoffice/program/fundamentalrc";
        };

        xdg = {
          configFile = {
            "LanguageTool/LibreOffice/.keep".source = builtins.toFile "keep" "";
          };

          mimeApps.associations.removed = lib.genAttrs [ "text/plain" ] (_: "libreoffice.desktop");
        };
      };
  };
}
