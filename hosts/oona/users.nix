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
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      # authorize login to ${user1} from host mack
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos.allen@gmail.com"
    ];
    # packages = with pkgs; [
    #   #  thunderbird
    # ];
  };

  # imports = [ ../../common/users/${user1}/linux.nix ];

}
