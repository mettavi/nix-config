{
  inputs,
  ...
}:
{

  imports = [
    inputs.sops-nix.homeManagerModules.sops
    ../../common/users/timotheos
  ];
}
