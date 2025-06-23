{ pkgs, username, ... }:
{
  # Define a user account. Don't forget to set a password with ‘passwd’.
  users.users.${username} = {
    isNormalUser = true;
    home = "/home/${username}";
    description = "Mettavihari";
    extraGroups = [
      "networkmanager"
      "wheel"
    ];
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      # authorize login to ${username} from host mack
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos.allen@gmail.com"
    ];
    # set zsh as the user's default on the host
    shell = pkgs.zsh;
    # packages = with pkgs; [
    #   #  thunderbird
    # ];
  };

  # imports = [ ../../common/users/${username}/linux.nix ];

}
