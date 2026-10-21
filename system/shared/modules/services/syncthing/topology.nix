{
  config,
  inputs,
  username,
  ...
}:
{
  devices = {
    oona.id = "QJ3EAEO-BK22DVP-DZ6SGFH-JSWJ6RI-T5KCKSE-MUMNMWS-Y2T5HHO-4GZX6A4";
    pixel.id = "PHMZ76M-RKYU66P-G7M3FEI-5R5FC2Z-DC5LVBG-7CSIQLP-KU5GZEB-YQIO4Q2";
    kindle.id = "S3YJCK4-6URNLBD-FO4UWWP-RVFGQ5C-5ZLFBYA-L5YLK4K-6FWXHMU-VSR2XQH";
    blue = {
      id = "6XHSTOA-RGKBBIQ-BHEU4GU-USTUQ7S-P3SCYUJ-HOLYUJ6-STNJSEQ-6PHSIQS";
      addresses = [ "tcp://sync.${inputs.secrets.domain.primary}:22000" ];
      untrusted = true;
    };
  };

  folders = {
    obsidian = {
      devices = [
        "oona"
        "pixel"
        "blue"
      ];
      paths.oona = config.mettavi.apps.obsidian.vaultsParent;
      settings = {
        # to apply this selectively, add it to
        # ...settings.folders.<name>.ignorePerms in the host file instead
        # ignorePerms = true;
        versioning = {
          type = "simple";
          params.keep = "10";
        };
      };
    };
    koreader = {
      devices = [
        "oona"
        "pixel"
        "kindle"
        "blue"
      ];
      paths.oona = "/home/${username}/Documents/koreader";
    };
  };
}
