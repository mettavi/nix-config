{ lib, pkgs, ... }:
{
  # use Avahi’s service discovery facilities
  services.avahi = {
    enable = true;
    nssmdns4 = true; # allows applications to resolve names in the .local domain
    openFirewall = true; # open UDP port 5353
  };

  # Enable sound with pipewire.
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    # allow applications (like Firefox) that expect PulseAudio to function correctly using PipeWire's implementation.
    pulse.enable = true; # pulseaudio emulation
    wireplumber.enable = true; # make the default explicit
  };

  # allow pipewire to have realtime priority
  security.rtkit.enable = true;

  # Enable CUPS printing service
  services.printing = {
    enable = lib.mkDefault true;
    drivers = with pkgs; [
      cups-filters
      cups-browsed
    ];
  };

  # pulseaudio is not recommended for T2 macs, see https://wiki.t2linux.org/guides/audio-config
  # ensure pulseaudio is disabled as gnome enables it by default
  services.pulseaudio.enable = lib.mkDefault false;

  # allows applications to query and manipulate storage devices (eg. for calibre)
  services.udisks2.enable = true;
}
