{
  hostname,
  inputs,
  username,
  ...
}:
{
  networking.hostName = "${hostname}";
  nixpkgs.hostPlatform = "x86_64-darwin";

  # the determinate insaller was used, so nix.* settings are managed in /etc/nix/nix.conf and nix.custom.conf
  # nix.enable = false;

  users.users.${username} = {
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos@oona"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII1n+RR5GUcqjFh7ypsw5bVOszWnZUa4VltzgK6eYGUv timotheos@salina"
    ];
  };

  # SYSTEM MODULES
  mettavi = {
    profiles = {
      dailydriver.enable = true;
    };
    system = {
      # enable system users
      userConfig = {
        timotheos = {
          enable = true;
        };
      };
    };
  };

  home-manager = {
    users.${username} = {
      home = {
        # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
        stateVersion = "23.11";
      };
      mettavi = {
        apps = {
          vscode.enable = true;
        };
        shell = {
          # enable scheduled bitwarden backup task
          bw_backup.enable = true;
        };
      };
    };
  };

  /*
        Previously, some nix-darwin options applied to the user running
    `   darwin-rebuild`. As part of a long‐term migration to make
        nix-darwin focus on system‐wide activation and support first‐class
        multi‐user setups, all system activation now runs as `root`, and
        these options instead apply to the `system.primaryUser` user.
        In the long run, this setting will be deprecated and removed after all the
        functionality it is relevant for has been adjusted to allow
        specifying the relevant user separately, moved under the
        `users.users.*` namespace, or migrated to Home Manager.
  */
  system.primaryUser = "${username}";

  # The Git revision of the top-level flake from which this configuration was built
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog and https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
  system.stateVersion = 5;
}
