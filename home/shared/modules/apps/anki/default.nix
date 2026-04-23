{
  config,
  inputs,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.apps.anki;
in
{
  options.mettavi.apps.anki = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure anki";
    };
  };

  config = mkIf cfg.enable {
    programs.anki = {
      enable = true;
      addons = [ ];
      answerKeys = [
        {
          ease = 1; # By default, 1 = Again, 2 = Hard, 3 = Good, and 4 = Easy
          key = "1";
        }
        {
          ease = 2;
          key = "2";
        }
        {
          ease = 3;
          key = "3";
        }
        {
          ease = 4;
          key = "4";
        }
      ];
      hideBottomBar = false;
      hideBottomBarMode = null; # null or one of "fullscreen", "always"
      hideTopBar = false;
      hideTopBarMode = null; # null or one of "fullscreen", "always"
      language = "en_AU"; # display language
      minimalistMode = false; # Minimalist user interface mode
      profiles = {
        "${config.home.username}" = {
          default = true;
          sync = {
            autoSync = true;
            autoSyncMediaMinutes = 0; # set to 0 to disable
            keyFile = null; # Path to a file containing the sync account sync key
            networkTimeout = 60; # secs
            syncMedia = true;
            url = null; # custom sync server
            username = inputs.secrets.email.personal;
            usernameFile = null;
          };
        };
      };
      # Disable various animations and transitions of the user interface
      reduceMotion = false;
      spacebarRatesCard = true; # Spacebar (or enter) also answers card.
      style = "native"; # null or one of "anki", "native"
      theme = "dark";
      uiScale = 1.0; # between 1.0 and 2.0
      # NB: selecting "vulkan" caused rendering problems in the GUI
      videoDriver = null;
    };
  };
}
