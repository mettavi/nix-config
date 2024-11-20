{
  lib,
  config,
  dream2nix,
  self,
  ...
}:
{
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-lock-v3
    dream2nix.modules.dream2nix.nodejs-granular-v3
  ];

  mkDerivation = {
    src = builtins.fetchGit {
      shallow = true;
      url = "https://github.com/denysdovhan/learnyoubash";
      ref = "package-lock-v3";
      rev = "496d6c628d15d2164ce80fd2c4198f162ffa6291";
    };
  };

  deps =
    { nixpkgs, ... }:
    {
      inherit (nixpkgs)
        fetchFromGitHub
        stdenv
        ;
    };

  nodejs-package-lock-v3 = {
    packageLockFile = "${config.mkDerivation.src}/package-lock.json";
  };

  name = "learnyoubash";
  version = "1.1.0";
}
