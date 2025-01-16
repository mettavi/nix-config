{
  inputs,
  config,
  ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
in
{

  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../common/users/timotheos
  ];
}
