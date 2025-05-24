{
  user1,
  config,
  ...
}:
{
  sops = {
    templates = {
      # gyb config file with secrets for timotheos.allen@gmail.com
      "client_secrets.json" = {
        content = ''
          {
            "installed": {
              "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
              "auth_uri": "https://accounts.google.com/o/oauth2/auth",
              "client_secret": "${
                config.sops.placeholder."users/${user1}/gyb-timotheos.allen@gmail.com/gyb_client_secret_timotheos"
              }",
              "redirect_uris": ["urn:ietf:wg:oauth:2.0:oob", "http://localhost"],
              "token_uri": "https://accounts.google.com/o/oauth2/token"
            }
          }
        '';
        path = "${config.xdg.configHome}/gyb/timotheos.allen@gmail.com/client_secrets.json";
      };
      "timotheos.allen@gmail.com.cfg" = {
        content = ''
          {
            "client_secret": "${config.sops.placeholder."users/${user1}/gyb-timotheos.allen@gmail.com/gyb_client_secret_timotheos"}",
            "decoded_id_token": {
              "email_verified": true,
              "exp": 1747886854,
              "iat": 1747883254,
              "iss": "https://accounts.google.com",
            },
            "token_expiry": "2025-05-22T04:07:33Z",
            "token_uri": "https://oauth2.googleapis.com/token"
          }
        '';
        path = "${config.xdg.configHome}/gyb/timotheos.allen@gmail.com/timotheos.allen@gmail.com.cfg";
      };
      "oauth2service.json" = {
        content = ''
          {
            "type": "service_account",
            "private_key": "${config.sops.placeholder."users/${user1}/gyb-timotheos.allen@gmail.com/gyb_oauth_private_key_timotheos"}",
            "auth_uri": "https://accounts.google.com/o/oauth2/auth",
            "token_uri": "https://oauth2.googleapis.com/token",
            "auth_provider_x509_cert_url": "https://www.googleapis.com/oauth2/v1/certs",
            "universe_domain": "googleapis.com"
          }
        '';
        path = "${config.xdg.configHome}/gyb/timotheos.allen@gmail.com/oauth2service.json";
      };
    };
  };
}
