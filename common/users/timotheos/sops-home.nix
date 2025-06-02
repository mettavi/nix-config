{
  user1,
  config,
  ...
}:
{
  imports = [
    ./sops-templates
  ];

  sops = {
    defaultSopsFile = ../../../modules/secrets/secrets.yaml; # must have no password!
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    # It's also possible to use a ssh key, but only when it has no password:
    #age.sshKeyPaths = [ "/home/user/path-to-ssh-key" ];

    secrets = {
      # SSH KEYS
      "users/${user1}/ssh_keys/timotheos_ed25519" = {
        path = "${config.home.homeDirectory}/.ssh/timotheos_ed25519";
      };
      "users/${user1}/ssh_keys/timotheos_ed25519.pub" = {
        path = "${config.home.homeDirectory}/.ssh/timotheos_ed25519.pub";
      };
      # oracle cloud
      "users/${user1}/ssh_keys/ssh-nixos-ocloud.key" = {
      };
      # RCLONE KEYS
      # rclone auth token for onedrive service
      "users/${user1}/rclone_keys/rclone_1d_token" = {
      };
      # rclone application key for backblaze b2 service
      "users/${user1}/rclone_keys/rclone_b2_appkey" = {
      };
      # rclone secret access key for AWS S3 Glacier Deep Archive bucket
      "users/${user1}/rclone_keys/rclone_aws_gda_key" = {
      };
      # rclone obfuscated encryption password
      "users/${user1}/rclone_keys/rclone_aws_gda_crypt" = {
      };
      # restic key for encryption of backblaze b2 repo (mbp_timotheos)
      "users/${user1}/restic_b2_mack-timotheos" = {
      };
      # bitwarden .env file for use with cli
      "users/${user1}/bitwarden.env" = { };
      "users/${user1}/cachix_auth_token" = {
      };
      "users/${user1}/github_token" = {
      };
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
