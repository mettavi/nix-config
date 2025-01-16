{
  inputs,
  config,
  pkgs,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  home = {
    username = "timotheos";
    homeDirectory = "/Users/timotheos";
    stateVersion = "23.11";
    # make programs use XDG directories whenever supported
    preferXdgDirectories = true;
  };
  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../common/users/timotheos
  ];

  ######## INSTALL SERVICES #########

  services = {
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program /usr/local/bin/pinentry-touchid
      '';
    };
  };
}
