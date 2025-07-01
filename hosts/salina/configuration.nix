{
  modulesPath,
  lib,
  username,
  pkgs,
  ...
}@args:
{
  imports = [
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
  services.openssh.enable = true;

  environment.systemPackages = map lib.lowPrio [
    pkgs.curl
    pkgs.gitMinimal
  ];

  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    description = "Mettavihari";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    openssh.authorizedKeys.keys = [
      # change this to your ssh key
      "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCxVXQ5CuMcbFSw8o/Rm8QS2IYFeDSXMi+BsG+bnF++/PAGYpPLShzSgigEBsdzu8+YBXQsa4r0Aj2686YHAahCm+aNg9YDBN/bvsFMGqXT/N3ApMRzutEUUOESC45Bt9VAeBDYOU56ConW8NQLOFRLfsernv62y4KM5upcFpUhKpfi2AOXVU+Njc7cNXRYdoL8lwKxIBL3/IMAP1wr1rYQYkS7lRGvd6uhw/NGAFaXvsZ9IBQwkxJFFce6FiUO6Sm5sSpUcGYPPVMUugmoFvTH8QI+SVCPhC3VQj85/utAWzuQoSMoFf5tj89vml/KppdphAohKOIwK/VATdJ7WG7N ssh-key-2025-03-07"
    ] ++ (args.extraPublicKeys or [ ]); # this is used for unit-testing this module and can be removed if not needed
  };

  system.stateVersion = "25.05";
}
