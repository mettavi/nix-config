{
  services = {
    gpg-agent = {
      enable = true;
      extraConfig = ''
        pinentry-program /usr/local/bin/pinentry-touchid
      '';
    };
  };
}
