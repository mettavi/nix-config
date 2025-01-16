{
  inputs,
  config,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{
  # install the HTML manual and "home-manager-help" command
  manual.html.enable = true;

  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../common/users/timotheos
  ];
}
