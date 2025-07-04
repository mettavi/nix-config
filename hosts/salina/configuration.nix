{
  lib,
  pkgs,
  ...
}@args:

let
  username = "timotheos";
in
{
  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      # authorize login to user timotheos from host oona
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos.allen@gmail.com"
      # authorize login to user timotheos from host mack
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos.allen@gmail.com"
    ] ++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed
  };

  system.stateVersion = "25.05";
}
