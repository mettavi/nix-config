{
  pkgs,
  config,
  inputs,
  ...
}:
{
  networking.hostName = "mack";

  imports = [
    ../../common/shared/default.nix
    ../../common/darwin/default.nix
    ../../modules/sops/sops-system.nix
  ];

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "x86_64-darwin";

  ########### CONFIGURE SYSTEM USERS ############

  users.users.ta = rec {
    name = "timotheos";
    home = "/Users/${name}";
    # authorize remote login to host using personal ssh key
    openssh.authorizedKeys.keys = [
      (builtins.readFile ../../modules/secrets/timotheos/keys/id_ed25519.pub)
    ];
  };

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 5;

  # List of directories to be symlinked in /run/current-system/sw
  environment.pathsToLink = [
    "/libexec"
    "/share/doc"
    "/share/zsh"
    "/share/man"
    "/share/bash-completion"
  ];

  # pam_reattach.so re-enables pam_tid.so in tmux
  environment.etc."pam.d/sudo_local".text = ''
    # Managed by Nix Darwin
    auth       optional       ${pkgs.pam-reattach}/lib/pam/pam_reattach.so ignore_ssh
    auth       sufficient     pam_tid.so
  '';

  fonts.packages = with pkgs; [
    nerd-fonts.meslo-lg
  ];

  services = {
    #   postgresql = {
    #     enable = true;
    #     dataDir = /usr/local/var/postgres;
    #   };
    #   redis = {
    #     enable = true;
    #   };
  };

  programs = {
    bash = {
      # this will enable and install bash-completion package (bash.enableCompletion is deprecated)
      completion.enable = true;
    };
    #   fish.enable = true;
    # Create /etc/zshrc that loads the nix-darwin environment.
    zsh = {
      enable = true;
      promptInit = "source ${pkgs.zsh-powerlevel10k}/share/zsh-powerlevel10k/powerlevel10k.zsh-theme";
    };
  };
}
