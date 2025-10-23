{ lib, ... }:
{
  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # not recommended for T2 macs, see https://wiki.t2linux.org/guides/audio-config
    # pulse.enable = true;
  };
  # used by pipewire
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;

  time.timeZone = lib.mkDefault "Australia/Melbourne";
}
