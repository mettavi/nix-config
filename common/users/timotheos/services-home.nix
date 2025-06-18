{ pkgs, ... }:
{
  services = {
    gpg-agent = {
      enable = true;
      extraConfig =
        if pkgs.stdenv.isDarwin then
          ''
            pinentry-program /usr/local/bin/pinentry-touchid
          ''
        else
          null;
    };
  };
}
