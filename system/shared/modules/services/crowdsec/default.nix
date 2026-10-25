{ modulesPath, ... }:
let
  hasLegacyModule = builtins.pathExists (modulesPath + "/services/security/crowdsec.nix");
in
{
  imports = [ (if hasLegacyModule then ./legacy.nix else ./current.nix) ];
}
