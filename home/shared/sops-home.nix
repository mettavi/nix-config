{
  config,
  hostname,
  secrets_path,
  ...
}:
let
  username = config.home.username;
  rcloneSecrets.sopsFile = "${secrets_path}/secrets/apps/rclone.yaml";
in
{
  imports = [
    ./sops-templates
  ];

  sops = {
    defaultSopsFile = "${secrets_path}/secrets/common.yaml"; # must have no password!
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    # It's also possible to use a ssh key, but only when it has no password:
    #age.sshKeyPaths = [ "/home/user/path-to-ssh-key" ];

    secrets = {
      # SSH KEYS
      "users/${username}/ssh_keys/${username}-${hostname}_ed25519" = {
        path = "${config.home.homeDirectory}/.ssh/${username}-${hostname}_ed25519";
        mode = "0600";
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
      "users/${username}/ssh_keys/${username}-${hostname}_ed25519.pub" = {
        path = "${config.home.homeDirectory}/.ssh/${username}-${hostname}_ed25519.pub";
        # ssh-agent on nixos would refuse to connect without changing the permissions from 0400
        mode = "0644";
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
      # RCLONE KEYS
      # rclone auth token for onedrive service
      "users/${username}/rclone_keys/rclone_1d_token" = rcloneSecrets;
      # rclone application key for backblaze b2 service
      "users/${username}/rclone_keys/rclone_b2_appkey" = rcloneSecrets;
      # rclone access key id for AWS S3 Glacier Deep Archive bucket
      "users/${username}/rclone_keys/rclone_aws_gda_keyid" = rcloneSecrets;
      # rclone access key secret for AWS S3 Glacier Deep Archive bucket
      "users/${username}/rclone_keys/rclone_aws_gda_keysecret" = rcloneSecrets;
      # rclone obfuscated encryption password
      "users/${username}/rclone_keys/rclone_aws_gda_crypt" = rcloneSecrets;
      # restic key for encryption of backblaze b2 repo (mbp_timotheos)
      "users/${username}/restic_b2_mack-timotheos" = {
      };
      # bitwarden .env file for use with cli
      "users/${username}/bitwarden.env" = { };
      "users/${username}/cachix_auth_token" = {
      };
      "users/${username}/github_token" = {
      };
      # .env file for use with systemd service for PIA VPN
      "users/${username}/pia.env" = { };
    };
    # secrets.test = {
    #   # sopsFile = ./secrets.yml.enc; # optionally define per-secret files
    #
    #   # %r gets replaced with a runtime directory, use %% to specify a '%'
    #   # sign. Runtime dir is $XDG_RUNTIME_DIR on linux and $(getconf
    #   # DARWIN_USER_TEMP_DIR) on darwin.
    #   path = "%r/test.txt";
    # };
  };
}
