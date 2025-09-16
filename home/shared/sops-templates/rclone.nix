{
  config,
  ...
}:
let
  username = config.home.username;
in
{
  sops = {
    templates = {
      # rclone config file with secrets
      # only "backend flags" can be added to the rclone.conf
      "rclone.conf" = {
        content = # bash
          ''
            [onedrive]
            type = onedrive
            token = ${config.sops.placeholder."users/${username}/rclone_keys/rclone_1d_token"}
            drive_id = 0F811515C935D85C
            drive_type = personal
            hard_delete = true
            # improves performance, except when used from the root (root/directory in onedrive:root/directory)
            delta = true

            [b2]
            type = b2
            account = 004471da6ad00020000000001
            key = ${config.sops.placeholder."users/${username}/rclone_keys/rclone_b2_appkey"}

            [aws_gda]
            type = s3
            provider = AWS
            access_key_id = ${config.sops.placeholder."users/${username}/rclone_keys/rclone_aws_gda_keyid"}
            secret_access_key = ${
              config.sops.placeholder."users/${username}/rclone_keys/rclone_aws_gda_keysecret"
            }
            region = us-east-1
            acl = private
            storage_class = DEEP_ARCHIVE

            [aws_gda-crypt]
            type = crypt
            remote = aws_gda:mettavi-archive-useast1
            # rclone obfuscated encryption password
            password = ${config.sops.placeholder."users/${username}/rclone_keys/rclone_aws_gda_crypt"}
            directory_name_encryption = false
          '';
        path = "${config.xdg.configHome}/rclone/rclone.conf";
      };
    };
  };
}
