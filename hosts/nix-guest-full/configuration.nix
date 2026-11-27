{
  modulesPath,
  pkgs,
  username,
  ...
}:
{
  imports = [
    "${modulesPath}/virtualisation/qemu-vm.nix"
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  users.users.root = {
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
    ];
  };

  users.users.timotheos = {
    isNormalUser = true;
    extraGroups = [ "wheel" ]; # Enable ‘sudo’ for the user.
    initialPassword = "test";
  };

  environment.systemPackages = with pkgs; [
    cowsay
    git
    lolcat
    vim
  ];

  mettavi.system = {
    userConfig = {
      timotheos.enable = true;
    };
  };

  networking.firewall.allowedTCPPorts = [
    22
  ];

  services.openssh.enable = true;

  system.stateVersion = "26.05";

  home-manager.users.${username} = {
    home = {
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "26.05";
    };
  };
}
