{
  config,
  hostname,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
{
  sops = {
    defaultSopsFile = "${secrets_path}/secrets/common.yaml";
    # If you use something different from YAML, you can also specify it here:
    #sops.defaultSopsFormat = "yaml";
    age = {
      # automatically import host SSH keys as age keys
      # NB: ssh host keys can be generated with the "ssh-keygen -A" command (or automatically with nixos)
      sshKeyPaths = [ "/etc/ssh/ssh_${hostname}_ed25519_key" ];
      # This will generate an age format private key from the host private ssh key if one does not exist
      # WARNING: Let this create the key automatically from the host private key; do not replace with the PUBLIC key
      generateKey = true;
      keyFile = "/var/lib/sops-nix/key.txt";
    };
    gnupg.sshKeyPaths = [ ];
    # secrets will be output to /run/secrets
    # e.g. /run/secrets/msmtp-password
    # secrets required for user creation are handled in respective ./users/<username>.nix files
    # because they will be output to /run/secrets-for-users and only when the user is assigned to a host.
    secrets = {
      # For home-manager a separate age key is used to decrypt secrets and must be placed onto the host. This is because
      # the user doesn't have read permission for the ssh service private key. However, we can bootstrap the age key from
      # the secrets decrypted by the host key, which allows home-manager secrets to work without manually copying over
      # the age key. These age keys are unique for the user on each host and are generated on their own (i.e. they are not derived
      # from an ssh key).
      "users/${username}/encryption_key_home" = {
        owner = "${config.users.users.${username}.name}";
        # We need to ensure the entire directory structure is that of the user...
        path = "${config.users.users.${username}.home}/.config/sops/age/keys.txt";
      };
      # nixos hashed user passwords
      "users/${username}/${username}-${hostname}-hashpw" = lib.mkIf pkgs.stdenv.isLinux {
        neededForUsers = true;
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
      "users/${username}/jellyfin_admin-lady" = {
        sopsFile = "${secrets_path}/secrets/hosts/lady.yaml";
      };
      # wifi passwords to configure wireless networks
      "users/${username}/wifi.env" = { };
    };
  };
  # The containing folders are created as root and if this is the first ~/.config/ entry,
  # the ownership is busted and home-manager can't target because it can't write into .config...
  # See: https://github.com/Mic92/sops-nix/issues/381
  system.activationScripts.sopsSetAgeKeyOwnership =
    let
      ageFolder = "${config.users.users.${username}.home}/.config/sops/age";
      user = config.users.users.${username}.name;
      group = if pkgs.stdenv.isDarwin then "staff" else "users";
    in
    ''
      mkdir -p ${ageFolder} || true
      chown -R ${user}:${group} "${config.users.users.${username}.home}/.config";
    '';
}
