{ lib, ... }:
{
  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # allow applications (like Firefox) that expect PulseAudio to function correctly using PipeWire's implementation.
    pulse.enable = true; # pulseaudio emulation
    wireplumber.enable = true; # make the default explicit
  };

  # pulseaudio is not recommended for T2 macs, see https://wiki.t2linux.org/guides/audio-config
  # ensure pulseaudio is disabled as gnome enables it by default
  services.pulseaudio.enable = lib.mkDefault false;

  # allow pipewire to have realtime priority
  security.rtkit.enable = true;

  # Enable touchpad support (enabled default in most desktopManager).
  services.libinput.enable = true;

  # Enable CUPS to print documents.
  services.printing.enable = lib.mkDefault true;
}
