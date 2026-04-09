{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.beets;
in
{
  options.mettavi.shell.beets = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure the beets music library manager";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      beets = {
        enable = true;
        package = (
          pkgs.beets.override {
            pluginOverrides = {
              chroma.enable = true;
              embedart.enable = true;
              fetchart.enable = true;
              lastgenre.enable = true;
              musicbrainz.enable = true;
              scrub.enable = true;
            };
          }
        );
        settings = {
          # global settings
          directory = "${config.home.homeDirectory}/media/music";
          library = "${config.xdg.dataHome}/beets/musiclibrary.db";
          import = {
            copy = true;
            log = "${config.xdg.dataHome}/logs/beets/import.log";
            move = false;
            write = true;
          };
          paths = {
            albumtype_soundtrack = "soundtracks/$album/$track $title";
            comp = "compilations/$album/$track $title";
            default = "$albumartist/$album/$track $title";
            singleton = "singles/$artist/$title";
          };
          plugins = [
            "chroma"
            "embedart"
            "fetchart"
            "lastgenre"
            "lyrics"
            "musicbrainz"
            "playlist"
            "replaygain"
            "scrub"
          ];
          # PLUGINS CONFIG
          embedart = {
            auto = true;
          };
          fetchart = {
            auto = true;
          };
          lyrics = {
            auto = true;
            synced = true;
          };
          replaygain = {
            auto = false;
          };
          scrub = {
            auto = true;
          };
        };
      };
    };
  };
}
