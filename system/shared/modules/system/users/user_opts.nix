{
  config,
  hostname,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.system.userConfig;
  cfg_username = cfg.myadmin.username;
in
{
  options.nyx.system.userConfig = mkOption {
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
            home = {
              type = types.str;
              default = if pkgs.stdenv.isDarwin then "/Users/${cfg_username}" else "/home/${cfg_username}";
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
              # allow user to configure networking and use sudo (nixos only)
              default = [
                "networkmanager"
                "wheel"
              ];
              description = "Additional groups for this user.";
            };
            shell = mkOption {
              type = types.package;
              default = pkgs.zsh;
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
