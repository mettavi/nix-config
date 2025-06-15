{ inputs, system, user1, ... }:
{
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ];
  home-manager = {
    useGlobalPkgs = true;
    useUserPackages = true;
    users.${user1} = import ../../common/users/${user1};
    # Optionally, use home-manager.extraSpecialArgs to pass
    # arguments to home-manager modules
    extraSpecialArgs = {
      inherit inputs system user1;
    };
    # sharedModules = [
    #   inputs.sops-nix.homeManagerModules.sops
    #   inputs.mac-app-util.homeManagerModules.default
    # ];
  };
}
