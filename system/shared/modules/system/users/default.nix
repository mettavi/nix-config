{
  config,
  inputs,
  pkgs,
  lib,
  ...
}:
with lib;
let
  # Get all users defined for your nix systems
  cfg = config.nyx.system;
in
{
  # make the user module options available
  imports = [
    ./user_opts.nix
    inputs.home-manager.darwinModules.home-manager
  ];

  config = {
    # create a database of all users managed by the nix system
    nyx.system.userConfig = {
      timotheos = {
        # pull encrypted "soft" secrets from private git rep
        fullname = inputs.secrets.name;
        description = "This is main admin account of the system";
        email = inputs.secrets.email.gitHub;
      };
    };

    # Use the declared options and user data to set up users on the system
    users.users =
      if pkgs.stdenv.isLinux then
        # nixos config
        mapAttrs (
          name: usrCfg:
          mkIf usrCfg.enable {
            name = usrCfg.username;
            description = usrCfg.description;
            home = "/home/${usrCfg.username}";
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
        mapAttrs (
          name: usrCfg:
          mkIf usrCfg.enable {
            name = usrCfg.username;
            description = usrCfg.description;
            home = "/Users/${usrCfg.username}";
            shell = usrCfg.shell;
          }
        ) cfg.userConfig;

    # home-manager.users = mapAttrs' (
    #   name: usrCfg:
    #   nameValuePair (usrCfg.username) (
    #     import ../../../../../lib/mkUserHome.nix {
    #       inherit (usrCfg) username;
    #       inherit pkgs;
    #     }
    #   )
    # ) cfg.userConfig;

    # the mapAttrs' (note the apostrophe) function allows to change the name as well as the value
    home-manager.users = mapAttrs' (
      name: usrCfg:
      nameValuePair (usrCfg.username) (
        mkIf usrCfg.enable {
          imports = [
            ../../../../../home/shared/dots.nix
            ../../../../../home/shared/programs.nix
            ../../../../../home/shared/sops-home.nix
            ../../../../../home/shared/modules
            ../../../../../home/darwin
            ../../../../../home/nixos
            ../../../../../users/${usrCfg.username}
          ];
          home = {
            # username and home are set automatically when using home-manager as a system module
            # username = "some_user";
            homeDirectory = mkForce (
              if pkgs.stdenv.isDarwin then "/Users/${usrCfg.username}" else "/home/${usrCfg.username}"
            );
            # make programs use XDG directories whenever supported
            preferXdgDirectories = true;
          };
        }
      )
    ) cfg.userConfig;

    # pass the primary admin user's username to other system modules
    _module.args.username = cfg.userConfig.myadmin.username;
  };
}
