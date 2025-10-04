{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.mettavi.profiles.vps;
in
{
  options.mettavi.profiles.vps = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "A profile for a virtual private/cloud server";
    };
  };

  config = mkIf cfg.enable {
    services.openssh =
      if pkgs.stdenv.isLinux then
        {
          settings = {
            # options to harden openssh, especially for servers
            # forbid the use of ssh password authentication
            PasswordAuthentication = false;
          };
        }
      else
        {
          extraConfig = ''
            PasswordAuthentication no
          '';
        };
  };
}
