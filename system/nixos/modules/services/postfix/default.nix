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
with lib;
let
  email = inputs.secrets.email.personal;
  cfg = config.mettavi.system.services.postfix;
in
{
  options.mettavi.system.services.postfix = {
    enable = mkOption {
      type = types.bool;
      default = false;
      description = "Set up and configure the postfix mail agent on nixos";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = with pkgs; [
      # includes the mail command, a user-friendly interface that allows you
      # to compose and send emails using sendmail in the background
      mailutils # protocol-independent mail framework
    ];
    services.postfix = {
      enable = true;
      settings.main = {
        # Force postfix to use IPv4 only, preventing the "Network is unreachable" IPv6 loops
        inet_protocols = "ipv4";
        relayhost = [ "[smtp.gmail.com]:587" ];
        smtp_sasl_auth_enable = "yes";
        # hash requires converting the password file with the postmap command; texthash avoids this
        smtp_sasl_password_maps = "texthash:${config.sops.templates."sasl_passwd-${hostname}".path}";
        # Modern systemd/postfix variables require explicitly setting these for Gmail
        smtp_sasl_security_options = "noanonymous";
        smtp_sasl_tls_security_options = "noanonymous";
        smtp_tls_security_level = "encrypt";
      };
      settings.master = {
        # Disable chroot sandboxing so Postfix can read /run/secrets/
        smtp = {
          chroot = false;
        };
        submission = {
          chroot = false;
        };
      };
      # optional: Forward mails to root (e.g. from cron jobs, smartd) to an email address
      virtual = ''
        inline:{ {root=${email}} }
      '';
    };

    systemd.services.postfix = {
      # Block postfix until sops-nix target finishes initializing secrets
      after = [ "sops-nix.target" ];
      wants = [ "sops-nix.target" ];
    };

    sops = {
      secrets."users/${username}/postfix_gmail-${hostname}" = {
        sopsFile = "${secrets_path}/secrets/hosts/${hostname}.yaml";
      };
      templates = {
        # config file to allow postfix to use my personal gmail account automatically
        "sasl_passwd-${hostname}" = {
          content = # bash
            ''
              [smtp.gmail.com]:587 ${email}:${
                config.sops.placeholder."users/${username}/postfix_gmail-${hostname}"
              }
            '';
          owner = "postfix";
          group = "postfix";
          mode = "0600";
          path = "/etc/postfix/sasl_passwd-${hostname}";
        };
      };
    };
  };
}
