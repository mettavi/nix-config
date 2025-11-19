{
  config,
  hostname,
  lib,
  ...
}:
with lib;
let
  cfg = config.mettavi.system.userConfig;
  cfg_username = cfg.timotheos.username;
in
{
  options.mettavi.system.userConfig = mkOption {
    type = types.attrsOf (
      types.submodule (
        { name, ... }:
        {
          options = {
            enable = mkOption {
              type = types.bool;
              default = false;
              description = "Whether to enable this user on the current host.";
            };
            username = mkOption {
              type = types.str;
              default = "timotheos";
              description = "The same as the attribute name, but useful for reference within the user module";
            };
            description = mkOption {
              type = types.str;
              default = "${cfg_username}";
              description = "A description of the user account.";
            };
            fullname = mkOption {
              type = types.str;
              default = name; # Default to the attribute name if not specified
              description = "The display name of the user.";
            };
            email = mkOption {
              type = types.str;
              default = "";
              description = "The email address of the user.";
            };
            passwordHashFile = mkOption {
              type = types.str;
              default =
                config.sops.secrets."users/${cfg_username}/nixos_users/${cfg_username}-${hostname}-hashpw".path;
              description = "The hashed password file for the user.";
            };
            sudo = mkOption {
              type = types.bool;
              default = false;
              description = "Whether the user has sudo privileges.";
            };
            isNormalUser = mkOption {
              type = types.bool;
              default = true;
              description = "Whether this user is a normal user.";
            };
            extraGroups = mkOption {
              type = types.listOf types.str;
              default = [
                # allow user to configure networking and use sudo
                "networkmanager"
                "wheel"
                # allow this user access to printer/scanner services
                "scanner"
                "lp"
              ];
              description = "Additional groups for this user.";
            };
            shell = mkOption {
              type = types.str;
              default = "zsh";
              description = "The default shell for this user.";
            };
          };
        }
      )
    );
    default = { };
    description = "User configurations for the current host.";
  };
}
