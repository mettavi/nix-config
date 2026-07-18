{ inputs, ... }:
# Function for NixOS system configuration
let
  mkNixosModules = hostname: system: username: {
    specialArgs = {
      inherit
        hostname
        inputs
        username
        ;
    };
    modules = [
      inputs.disko.nixosModules.disko
      ../hosts/${hostname}/configuration.nix
      {
        users.users.${username} = {
          isNormalUser = true;
          home = "/home/${username}";
          # allow user to configure networking and use sudo
          extraGroups = [
            "networkmanager"
            "wheel"
          ];
        };
        networking.hostName = "${hostname}";
        nix = {
          extraOptions = ''
            warn-dirty = false
          '';
          settings = {
            # enable flakes
            experimental-features = [
              "nix-command"
              "flakes"
            ];
          };
        };
        programs = {
          git.enable = true;
          vim.enable = true;
        };
        # Enable the OpenSSH daemon.
        services = {
          openssh = {
            enable = true;
            # create a host key
            hostKeys = [
              {
                comment = "root@${hostname}";
                path = "/etc/ssh/ssh_${hostname}_ed25519_key";
                rounds = 100;
                type = "ed25519";
              }
            ];
            settings.PermitRootLogin = "prohibit-password";
          };
        };
        # The Git revision of the top-level flake from which this configuration was built
        system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;
      }
    ];
    # only valid when nixosSystem builds pkgs itself from scratch --
    # pkgs.testers.runNixOSTest supplies a pre-built, read-only pkgs, so
    # this must NOT be included in that path
    standaloneModules = [
      {
        nixpkgs = {
          config.allowUnfree = true;
          hostPlatform = system;
        };
      }
    ];
  };
in
{
  inherit mkNixosModules;

  # Function for NixOS system configuration
  mkNixosConfiguration =
    hostname: system: username: nixinput:
    let
      built = mkNixosModules hostname system username;
    in
    inputs.${nixinput}.lib.nixosSystem {
      inherit system;
      inherit (built) specialArgs;
      modules = built.modules ++ built.standaloneModules;
    };
}
