{
  config,
  inputs,
  user,
}:
{
  imports = [
    inputs.sops-nix.darwinModules.sops
  ];
  sops = {
    defaultSopsFile = ./secrets.yaml;
    # If you use something different from YAML, you can also specify it here:
    #sops.defaultSopsFormat = "yaml";
    age = {
      # automatically import host SSH keys as age keys
      # NB: ssh host keys can be generated with the "ssh-keygen -A" command
      sshKeyPaths = [ "/etc/ssh/ssh_host_ed25519_key" ];
      keyFile = "/var/lib/sops-nix/key.txt";
      # This will generate a new key if the key specified above does not exist
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
      # the age key.
      # These age keys are unique for the user on each host and are generated on their own (i.e. they are not derived
      # from an ssh key).
      encryption_key = {
        owner = "${user}";
        # We need to ensure the entire directory structure is that of the user...
        path = "${config.hostSpec.home}/.config/sops/age/keys.txt";
      };
      github_token = {
        owner = "${user}";
      };
      cachix_auth_token = {
        owner = "${user}";
      };
    };
  };
}
