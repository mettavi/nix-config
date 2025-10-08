{
  config,
  hostname,
  lib,
  ...
}:
let
  cfg = config.mettavi.shell.syncthing;
  cert_pem = "users/${config.home.username}/syncthing/st_${hostname}_cert.pem";
  key_pem = "users/${config.home.username}/syncthing/st_${hostname}_key.pem";
  gui_pw = "users/${config.home.username}/syncthing/st_${hostname}_guipw";
  gui_apikey = "users/${config.home.username}/syncthing/st_${hostname}_guiapikey";
in
{
  options.mettavi.shell.syncthing = {
    enable = lib.mkEnableOption "Install and configure syncthing";
  };

  config = lib.mkIf cfg.enable {
    # a specific module option has been requested at
    home.file."Library/Application Support/Syncthing/.stignore".text = # bash
      ''
        .DS_Store
      '';
    services.syncthing = {
      enable = true;
      extraOptions = [ ];
      cert = "${config.sops.secrets.${cert_pem}.path}";
      key = "${config.sops.secrets.${key_pem}.path}";
      overrideDevices = true;
      overrideFolders = true;
      # contains bcrypt hashed pw
      passwordFile = "${config.sops.secrets.${gui_pw}.path}";
      settings = {
        folders = {
          "koreader" = {
            devices = [
              "Kindle Oasis"
              "Pixel 8 Pro"
            ];
            id = "default";
            path = "~/Library/Application Support/koreader/Books/Sync";
            versioning.type = "simple";
          };
        };
        devices = {
          "Kindle Oasis".id = "S3YJCK4-6URNLBD-FO4UWWP-RVFGQ5C-5ZLFBYA-L5YLK4K-6FWXHMU-VSR2XQH";
          "Pixel 8 Pro".id = "PHMZ76M-RKYU66P-G7M3FEI-5R5FC2Z-DC5LVBG-7CSIQLP-KU5GZEB-YQIO4Q2";
        };
        gui = {
          # builtin themes: default, dark, black, light
          theme = "black";
          user = "mettavi";
        };
        options = {
          # do not enable anonymous usage reporting
          urAccepted = -1;
        };
      };
    };
    sops.secrets = {
      "${cert_pem}" = { };
      "${key_pem}" = { };
      "${gui_pw}" = { };
      "${gui_apikey}" = { };
    };
  };
}
