{ user1, ... }:
{
  users.users.${user1} = {
    name = "${user1}";
    home = "/Users/${user1}";
    # authorize remote login to host using personal ssh key
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../common/users/${user1}/keys/timotheos_ed25519.pub)
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
