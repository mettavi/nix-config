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
    home.file."${nix_repo}/.githooks/pre-commit".text = # bash
    ''
      #!/usr/bin/env bash
      ".gitconfig".source = ../../../dots/git/.gitconfig;
      ".gitignore_global".source = ../../../dots/git/.gitignore_global;

      # commit current version of nvim (Lazy) plugins catalogue
      echo
      echo "Checking for changes to lazy-lock.json..."
      echo
      git add home/shared/dots/nvim/lazy-lock.json

      # check staged files for secrets
      echo "Checking for secrets..."
      echo
      gitleaks protect --staged -v
    ''
    # only use this code on host oona
    +
      lib.optionalString (hostname == "oona") # bash
        ''

          # Get current branch and the hash we are building ON TOP OF
          BRANCH=$(git rev-parse --abbrev-ref HEAD)
          PREV_HASH=$(git rev-parse --short HEAD)

          echo "🛡️ Pre-commit safety snapshot starting..."

          # Snapshot the state BEFORE the commit happens
          snapper -c adminhome create \
            --description "Pre-commit: $BRANCH (Base: $PREV_HASH)" \
            --userdata "type=git-pre-safety,branch=$BRANCH"

          if [ $? -eq 0 ]; then
            echo "✅ Safety snapshot created. Proceeding with commit..."
          else
            echo "❌ Snapper failed! Commit aborted for safety."
            exit 1
          fi
        '';
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
      settings = {
        user = {
          email = inputs.secrets.email.gitHub;
          name = inputs.secrets.name;
        };
      };
    };
  };
}
