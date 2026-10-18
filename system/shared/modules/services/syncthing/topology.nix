{ inputs, ... }:
{
  devices = {
    laptop.id = "QJ3EAEO-BK22DVP-DZ6SGFH-JSWJ6RI-T5KCKSE-MUMNMWS-Y2T5HHO-4GZX6A4";
    pixel.id = "BBBBBBB-...";
    kindle.id = "CCCCCCC-...";
    vps = {
      id = "DDDDDDD-...";
      addresses = [ "tcp://pangolin.${inputs.secrets.domain.primary}:22000" ];
      untrusted = true;
    };
  };

  folders = {
    obsidian = {
      devices = [
        "laptop"
        "pixel"
        "vps"
      ];
      paths.laptop = "/home/you/Documents/Obsidian";
      settings.versioning = {
        type = "simple";
        params.keep = "10";
      };
    };
    koreader = {
      devices = [
        "laptop"
        "pixel"
        "kindle"
        "vps"
      ];
      paths.laptop = "/home/you/Documents/koreader";
    };
  };
}
