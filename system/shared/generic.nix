{ lib, ... }:
{
  # List of directories to be symlinked in /run/current-system/sw
  environment = {
    pathsToLink = [
      "/libexec"
      "/share/bash-completion"
      "/share/applications"
      "/share/doc"
      "/share/icons"
      "/share/man"
      "/share/zsh"
    ];
  };

  # Set your time zone.
  time.timeZone = lib.mkDefault "Australia/Melbourne";

}
