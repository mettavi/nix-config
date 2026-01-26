{
  config,
  lib,
  pkgs,
  username,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.apps.brave;
in
{
  options.mettavi.system.apps.brave = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Install and configure chromium or one of its relatives";
    };
  };
  config = mkIf cfg.enable {
    # see https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for a list of brave policy settings
    environment.etc."/brave/policies/managed/GroupPolicy.json".source = ./policies.json;

    home-manager.users.${username} = {
      programs.brave = {
        enable = true;
        dictionaries = [
          pkgs.hunspellDictsChromium.en_US
        ];
        # NB: In order to install extensions in brave, use programs.brave rather than programs.chromium
        extensions = [
          { id = "nngceckbapebfimnlniiiahkandclblb"; } # bitwarden
          { id = "eimadpbcbfnmbkopoojfekhnkhdbieeh"; } # dark reader
          { id = "hipekcciheckooncpjeljhnekcoolahp"; } # tabliss
          { id = "iaiomicjabeggjcfkbimgmglanimpnae"; } # tab session messenger
          { id = "cjpalhdlnbpafiamejdnhcphjbkeiagm"; } # ublock origin
        ];
        commandLineArgs = [
          # there are problems with vulkan and hardware acceleration on wayland
          # until these are fixed, disable hw accel to get video working
          # see https://github.com/NixOS/nixpkgs/pull/378184
          "--disable-features=AutofillSavePaymentMethods"
          "--disable-gpu"
          "--disable-gpu-compositing"
        ];
        package = pkgs.brave;
      };
      xdg.configFile = {
        # NB: Currently, bitwarden only supports system authentication in Firefox, Chome and Edge
        # See https://github.com/bitwarden/clients/issues/11750
        # and https://github.com/bitwarden/clients/pull/16705
        # Workaround: 1. create the google-chome directory to get bitwarden to create the com.8bit.bitwarden.json file
        "google-chrome/NativeMessagingHosts/.keep".text = "";
        # 2. link the file to the Brave directory to get system authentication working
        "BraveSoftware/Brave-Browser/NativeMessagingHosts/com.8bit.bitwarden.json".source =
          ./com.8bit.bitwarden.json;
      };
    };
  };
}
