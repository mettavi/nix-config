{
  config,
  inputs,
  lib,
  username,
  ...
}:
with lib;
let
  email = inputs.secrets.email.personal;
  cfg = config.mettavi.system.shell.postfix;
in
{
  options.mettavi.system.shell.postfix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure the postfix mail agent on nixos";
    };
  };

  config = mkIf cfg.enable {
    services.postfix = {
      enable = true;
      relayHost = "smtp.gmail.com";
      relayPort = 587;
      config = {
        smtp_use_tls = "yes";
        smtp_sasl_auth_enable = "yes";
        smtp_sasl_security_options = "";
        # using texthash instead of hash simplifies the setup on nixos
        smtp_sasl_password_maps = "texthash:/etc/postfix/sasl_passwd";
        # optional: Forward mails to root (e.g. from cron jobs, smartd) to an email address
        virtual_alias_maps = "inline:{ {${email}} }";
      };
    };
    sops = {
      secrets."users/${username}/postfix_gmail-oona" = {
        owner = config.services.postfix.user;
      };
      templates = {
        # config file to allow postfix to use my personal gmail account automatically
        "sasl_passwd" = {
          content = # bash
            ''
              [smtp.gmail.com]:587 ${email}:${config.sops.placeholder."users/${username}/postfix_gmail-oona"}
            '';
          path = "/etc/postfix/sasl_passwd";
        };
      };
    };
  };
}
