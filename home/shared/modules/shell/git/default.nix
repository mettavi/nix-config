{
  config,
  hostname,
  inputs,
  lib,
  nix_repo,
  ...
}:
with lib;
let
  cfg = config.mettavi.shell.git;
  homeDir = "${config.home.homeDirectory}";
in
{
  options.mettavi.shell.git = {
    enable = lib.mkOption {
      description = "Install and configure git";
      type = types.bool;
      default = true;
    };
  };

  config = lib.mkIf cfg.enable {
    home.file = {
      ".gitconfig".source = ../../../dots/git/.gitconfig;
      ".gitignore_global".source = ../../../dots/git/.gitignore_global;
      "${nix_repo}/.githooks/pre-commit" = {
        executable = true;
        text = # bash
          ''
            #!/usr/bin/env bash

            # commit current version of nvim (Lazy) plugins catalogue
            echo
            echo "Checking for changes to lazy-lock.json..."
            echo
            git add home/shared/dots/nvim/lazy-lock.json

            # check staged files for secrets
            echo "Checking for secrets..."
            echo
            gitleaks protect --staged -v
          '';
      };
    };
    programs.git = {
      enable = true;
      # delta.enable = true;
      # include config files from a non-default location
      includes = [
        {
          path = "~/${nix_repo}/.gitconfig";
          condition = "gitdir:~/${nix_repo}/.git";
        }
      ];
      # enable automatic maintenance of git repos using launchd/systemd
      maintenance = {
        enable = true;
        repositories = [ "${homeDir}/${nix_repo}" ];
        timers = {
          daily = "Tue..Sun *-*-* 0:53:00";
          hourly = "*-*-* 1..23:53:00";
          weekly = "Mon 0:53:00";
        };
      };
      # set to remove evaluation warning about the changed default value
      signing.format = null;
      settings = {
        user = {
          email = inputs.secrets.email.gitHub;
          name = inputs.secrets.name;
        };
      };
    };
  };
}
