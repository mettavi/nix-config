{
  hostname,
  lib,
  modulesPath,
  pkgs,
  username,
  ...
}@args:

{
  imports = [
    # imports for initial install with nixos-anywhere and disko
    # subsequently the disko config will configure fstab
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  boot.loader.grub = {
    # no need to set devices, disko will add all devices that have a EF02 partition to the list already
    # devices = [ ];
    efiSupport = true;
    efiInstallAsRemovable = true;
  };

  services.openssh = {
    enable = true;
    # create a host key
    hostKeys = [
      {
        comment = "root@${hostname}";
        path = "/etc/ssh/ssh_${hostname}_ed25519_key";
        rounds = 100;
        type = "ed25519";
      }
    ];
  };

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.${username} = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
    ] ++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed
  };

  system.stateVersion = "25.05";
}
