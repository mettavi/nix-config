{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:
let
  email = inputs.secrets.email.personal;
in
{
  sops = {
    defaultSopsFile = "${secrets_path}/secrets.yaml";
    # If you use something differentfrom YAML, you can also specify it here:
    #sops.defaultSopsFormat = "yaml";
    age = {
      # automatically import host SSH keys as age keys
      # NB: ssh host keys can be generated with the "ssh-keygen -A" command (or automatically with nixos)
      sshKeyPaths = [ "/etc/ssh/ssh_${hostname}_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will generate an age format key from the host ssh key if one does not exist
      generateKey = true;
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
      "users/${username}/nixos_users/${username}-${hostname}-hashpw" = lib.mkIf pkgs.stdenv.isLinux {
        neededForUsers = true;
      };
      "users/${username}/google_timotheos_app_pw" = {
      };
    };
    templates = {
      # config file to allow postfix to use my personal gmail account automatically
      "sasl_passwd" = {
        content = # bash
          ''
            [smtp.gmail.com]:587 ${email}:${config.sops.placeholder."users/${username}/google_timotheos_app_pw"}
          '';
        path = "/etc/postfix/sasl_passwd";
      };
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
