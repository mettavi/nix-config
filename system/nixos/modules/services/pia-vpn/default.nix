{
  config,
  inputs,
  lib,
  username,
  ...
}:
let
  cfg = config.mettavi.system.services.pia-vpn;
  hm = config.home-manager.users.${username};
in
{
  options.mettavi.system.services.pia-vpn = {
    enable = lib.mkEnableOption "Install and set up the Private Internet Access VPN module";
  };

  config = lib.mkIf cfg.enable {
    imports = [ inputs.pia-vpn.nixosModules.default ];
    services.pia-vpn = {
      enable = true;
      certificateFile = ./ca.rsa.4096.crt;
      # environmentFile = "${config.home-manager.users.${username}.sops.secrets."users/${username}/pia.env".path
      environmentFile = "${hm}.sops.secrets.\"users/${username}/pia.env\".path"; # use sops-nix or agenix
    };
  };
}
