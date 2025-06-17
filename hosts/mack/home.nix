{ hostname, inputs, nix_repo, self, system, username, ... }:
{
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${username} = import ../../common/users/${username};
    # Optionally, use home-manager.extraSpecialArgs to pass
    # arguments to home-manager modules
    extraSpecialArgs = {
      inherit hostname inputs nix_repo self system username;
    };
    sharedModules = [
      inputs.sops-nix.homeManagerModules.sops
      inputs.mac-app-util.homeManagerModules.default
    ];
  };
}
