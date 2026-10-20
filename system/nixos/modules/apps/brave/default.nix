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
      description = "Install and configure the Brave browser";
    };
  };
  config = mkIf cfg.enable {
    # see https://support.brave.app/hc/en-us/articles/360039248271-Group-Policy for a list of brave policy settings
    # see https://gist.github.com/hoyhoy/1c675f6f02118f6e0db7616c070917ac for example settings
    environment.etc."/brave/policies/managed/GroupPolicy.json".source = ./policies.json;

    # prevent brave phoning home to the following urls
    networking.hosts = {
      "0.0.0.0" = [
        "p3a.brave.com"
        "rewards.brave.com"
        "api.rewards.brave.com"
        "grant.rewards.brave.com"
        "variations.brave.com"
        "laptop-updates.brave.com"
        "static1.brave.com"
        "crlsets.brave.com"
        "static.brave.com"
        "ads.brave.com"
        "ads-admin.brave.com"
        "ads-help.brave.com"
        "referrals.brave.com"
        "analytics.brave.com"
        "search.anonymous.ads.brave.com"
        "star-randsrv.bsg.brave.com"
        "usage-ping.brave.com"
        "sync-v2.brave.com"
        "redirector.brave.com"
      ];
    };

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
        # see https://support.brave.app/hc/en-us/articles/360044860011-How-Do-I-Use-Command-Line-Flags-in-Brave
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
    };
  };
}
