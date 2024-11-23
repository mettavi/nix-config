{
  lib,
  config,
  dream2nix,
  ...
}:
{
  imports = [
    dream2nix.modules.dream2nix.nodejs-package-json-v3
    dream2nix.modules.dream2nix.nodejs-granular-v3
  ];

  name = "regex-adventure";
  version = "1.1.2";

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
      url = "https://github.com/workshopper/regex-adventure";
      ref = "package-json-v3";
      rev = "03bc334616d7b1a45af746a2155ac3a81dd4a8c7";
    };
  };
}
