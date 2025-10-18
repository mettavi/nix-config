{
  inputs,
  pkgs,
  ...
}:
{
  nix = {
    enable = true;
    package = pkgs.lixPackageSets.stable.lix;
  };
  nixpkgs = {
    overlays = [
      # install from PR https://github.com/NixOS/nixpkgs/pull/451386 until it is merged to nixpkgs-unstable
      # TODO: Check status at https://nixpk.gs/pr-tracker.html?pr=451386
      (
        self: super:
        (
          let
            nixpkgs-rubyfix = import inputs.nixpkgs-rubyfix {
              inherit (self) system;
            };
          in
          {
            ruby = nixpkgs-rubyfix.ruby;
          }
        )
      )
    ]
    ++ [ (import ../overlays/darwin/default.nix) ];
  };
}
