{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.myUserConfig; # Define a namespace for your options
in
{
  options.myUserConfig = {
    users = mkOption {
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
                description = "The username on the system";
              };
              name = mkOption {
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
                  config.sops.secrets."users/${config.myUserConfig.users.myadmin.username}/nixos_users/${username}-${hostname}-hashpw".path;
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
                default = [ ];
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
  };

  # Use the declared options to configure actual users
  config = mkIf (cfg.users != { }) {
    users.users =
      if pkgs.stdenv.isLinux then
        mapAttrs' (
          name: userCfg:
          mkIf userCfg.enable {
            name = name;
            isNormalUser = userCfg.isNormalUser;
            hashedPasswordFile = userCfg.passwordHashFile;
            extraGroups = userCfg.extraGroups;
            shell = userCfg.shell;
          }
        )
      else
        # darwin config
        mapAttrs' (
          name: userCfg:
          mkIf userCfg.enable {
            name = name;
            shell = userCfg.shell;
          }
        ) cfg.users;
  };
}
