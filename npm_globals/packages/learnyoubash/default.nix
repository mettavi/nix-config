{
  lib,
  config,
  dream2nix,
  self,
  ...
}:
{
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-json-v3
    dream2nix.modules.dream2nix.nodejs-granular-v3
  ];

  name = "learnyoubash";
  version = "1.1.0";

  deps =
    { nixpkgs, ... }:
    {
      inherit (nixpkgs)
        fetchFromGitHub
        stdenv
        ;
    };

  mkDerivation = {
    src = builtins.fetchGit {
      shallow = true;
      url = "https://github.com/denysdovhan/learnyoubash";
      ref = "1.1.0";
      rev = "496d6c628d15d2164ce80fd2c4198f162ffa6291";
    };
  };

  # nodejs-package-lock-v3 = {
  #   packageFile = "${config.mkDerivation.src}/package.json";
  # };

}
