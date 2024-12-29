{
  inputs,
  config,
  user,
  ...
}:
{
  imports = [ inputs.sops-nix.homeManagerModules.sops ];

  sops = {
    defaultSopsFile = ./secrets.yaml; # must have no password!
    age.keyFile = "${config.xdg.configHome}/sops/age/keys.txt";
    # It's also possible to use a ssh key, but only when it has no password:
    #age.sshKeyPaths = [ "/home/user/path-to-ssh-key" ];

    secrets = {
      "private_keys/id_ed25519" = {
        path = "/Users/${user}/.ssh/id_ed25519";
      };
      "private_keys/id_ed25519.pub" = {
        path = "/Users/${user}/.ssh/id_ed25519.pub";
        mode = "0644";
      };
    };
    # secrets.test = {
    #   # sopsFile = ./secrets.yml.enc; # optionally define per-secret files
    #
    #   # %r gets replaced with a runtime directory, use %% to specify a '%'
    #   # sign. Runtime dir is $XDG_RUNTIME_DIR on linux and $(getconf
    #   # DARWIN_USER_TEMP_DIR) on darwin.
    #   path = "%r/test.txt";
    # };
  };
}
