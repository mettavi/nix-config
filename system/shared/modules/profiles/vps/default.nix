{
  config,
  lib,
  ...
}:
with lib;
let
  cfg = config.nyx.profiles.vps;
in
{
  options.nyx.profiles.vps = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for a virtual private/cloud server";
    };
  };

  config = mkIf cfg.enable {
    services.openssh = {
      settings = {
      # options to harden openssh, especially for servers
      # forbid the use of ssh password authentication
      PasswordAuthentication = false;
      };
    };
  };
}
