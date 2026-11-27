{ config, lib, pkgs, inputs, ... }:
let
  runtimeDir = "${config.home.homeDirectory}/.local/state/run";
in
{
  _module.args.sops_username = "timotheos";
  imports = [
    # Add your shared Neovim/shell/git Home Manager modules here, e.g.:
        ../../home/shared/dots.nix
        ../../home/shared/programs.nix
        ../../home/shared/sops-home.nix
       # ../../home/shared/modules
        ../../home/shared/modules/shell/git
    # ../../home/shared/modules/shell/nvim-wrap
  ];

  # Ensure XDG_RUNTIME_DIR is exported in interactive shells on Nix-on-Droid
  home.sessionVariables = {
    XDG_RUNTIME_DIR = runtimeDir;
  };

  # Automatically decrypt and link sops-nix secrets during Home Manager activation
  # (since Nix-on-Droid does not run a systemd --user daemon)
  home.activation.installSopsSecrets = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    mkdir -p "${runtimeDir}"
    chmod 700 "${runtimeDir}"
    if [ -f "${config.xdg.configHome}/systemd/user/sops-nix.service" ]; then
      exec_cmd=$(sed -n 's/^ExecStart=//p' "${config.xdg.configHome}/systemd/user/sops-nix.service")
      if [ -n "$exec_cmd" ]; then
        XDG_RUNTIME_DIR="${runtimeDir}" $DRY_RUN_CMD $exec_cmd
      fi
    fi
  '';

  mettavi.shell.git.enable = true;

  # Use sops-nix's own package output (built against its own nixpkgs with Go >= 1.26)
  sops.package = inputs.sops-nixos.packages.${pkgs.stdenv.hostPlatform.system}.sops-install-secrets;

  home = {
    username = "nix-on-droid";
    homeDirectory = "/data/data/com.termux.nix/files/home";
    stateVersion = "24.05";
  };

  # Quick test if you don't import a shared Neovim module yet:
  programs.neovim = {
    enable = true;
    defaultEditor = true;
    viAlias = true;
    vimAlias = true;
  };

  home.packages = with pkgs; [
    rclone
    ripgrep
    fd
  ];

 # mettavi.shell.nvim-wrap.enable = true;
}
