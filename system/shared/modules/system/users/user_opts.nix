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
  cfg_username = cfg.users.myadmin.username;
in
{
  options.nyx.system.userConfig = {
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
              description = mkOption {
                type = types.str;
                default = "${cfg_username}";
                description = "A description of the user account";
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
  };

  # Use the declared options to configure actual users
  config = mkIf (cfg.users != { }) {
    users.users =
      if pkgs.stdenv.isLinux then
        # nixos config
        mapAttrs' (
          name: usrCfg:
          mkIf usrCfg.enable {
            name = usrCfg.username;
            description = usrCfg.description;
            home = /home/${usrCfg.username};
            isNormalUser = usrCfg.isNormalUser;
            # this is required to enable password login
            # (create hash with "mkpasswd -m sha-512", or "mkpasswd" to use the stronger default "yes" encryption)
            hashedPasswordFile = usrCfg.passwordHashFile;
            extraGroups = usrCfg.extraGroups;
            shell = usrCfg.shell;
          }
        )
      else
        # darwin config
        mapAttrs' (
          name: usrCfg:
          mkIf usrCfg.enable {
            name = usrCfg.username;
            description = usrCfg.description;
            home = /Users/${usrCfg.username};
            shell = usrCfg.shell;
          }
        ) cfg.users;

    home-manager.users.${cfg_username} = import ../../../../../lib/mkUserHome.nix {
      inherit (cfg.users.myadmin) username;
    };
  };
}
