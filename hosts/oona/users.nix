{ user1, ... }:
{
    # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${user1} = {
    isNormalUser = true;
    home = "/home/${user1}";
    description = "Mettavihari";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # authorize remote login to host using personal ssh key
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../common/users/${user1}/keys/timotheos_ed25519.pub)
    ];
    # packages = with pkgs; [
    #   #  thunderbird
    # ];
  };

  # imports = [ ../../common/users/${user1}/linux.nix ];

}
