{ user1, ... }:
{
  users.users.${user1} = {
    name = "${user1}";
    home = "/Users/${user1}";
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      # authorize login to ${user1} from host oona
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILLefqc5FD0nZQLMUF6xfUTSZItumpd7AWPe0MP2JzoI timotheos.allen@gmail.com"
    ];
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
  system.primaryUser = "${user1}";

  imports = [ ../../common/users/${user1}/darwin.nix ];

}
