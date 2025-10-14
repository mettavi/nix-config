{ lib, ... }:
{
  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
  };
  # used by pipewire and pulseaudio 
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;

  time.timeZone = lib.mkDefault "Australia/Melbourne";
}
