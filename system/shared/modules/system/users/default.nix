{
  config,
  inputs,
  lib,
  pkgs,
  ...
}:
with lib;
let
  platform = if pkgs.stdenv.isDarwin then "darwin" else "nixos";
  # Get all users defined for your nix systems
  cfg = config.mettavi.system;
in
{
  # make the user module options available
  imports = [
    ./user_opts.nix
  ];

  config = {
    # create a database of users for all nix systems
    mettavi.system.userConfig = {
      timotheos = {
        # pull encrypted "soft" secrets from private git rep
        fullname = inputs.secrets.name;
        description = "Mettavihari";
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
            description = usrCfg.description;
            home = "/home/${usrCfg.username}";
            isNormalUser = usrCfg.isNormalUser;
            # this is required to enable password login
            # (create hash with "mkpasswd -m sha-512", or "mkpasswd" to use the stronger default "yes" encryption)
            hashedPasswordFile = usrCfg.passwordHashFile;
            extraGroups = usrCfg.extraGroups;
            shell = pkgs.${usrCfg.shell};
          }
        ) cfg.userConfig
      else
        # darwin config
        mapAttrs (
          name: usrCfg:
          mkIf usrCfg.enable {
            description = usrCfg.description;
            home = "/Users/${usrCfg.username}";
            shell = pkgs.${usrCfg.shell};
          }
        ) cfg.userConfig;

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
            ../../../../../home/${platform}
            ../../../../../users/${usrCfg.username}
          ];
          home = {
            # username and homeDirectory are set automatically when using home-manager as a system module
            # username = "${usrCfg.username}";
            # homeDirectory =
            #   if pkgs.stdenv.isDarwin then "/Users/${usrCfg.username}" else "/home/${usrCfg.username}";
            # make programs use XDG directories whenever supported
            preferXdgDirectories = true;
          };
        }
      )
    ) cfg.userConfig;

    # pass the primary admin user's username to other system modules
    _module.args.username = cfg.userConfig.timotheos.username;
    # NB: setting _module.args to a value from config will cause an infinite recursion
    # _module.args.username = config.users.users.timotheos.name;
  };
}
