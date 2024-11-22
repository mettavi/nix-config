{
  lib,
  config,
  dream2nix,
  ...
}: {
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-lock-v3
    dream2nix.modules.dream2nix.nodejs-granular-v3
  ];

  mkDerivation = {
    src = builtins.fetchGit {
      shallow = true;
      url = "https://github.com/workshopper/javascripting";
      ref = "package-lock-v3";
      rev = "661b90facecdde88e0afb860a5fc3cd704ad4226";
    };
  };

  deps = {nixpkgs, ...}: {
    inherit
      (nixpkgs)
      fetchFromGitHub
      stdenv
      ;
  };

  nodejs-package-lock-v3 = {
    packageLockFile = "${config.mkDerivation.src}/package-lock.json";
  };

  name = "javascripting workshop";
  version = "2.7.3";
}
