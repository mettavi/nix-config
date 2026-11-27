{ pkgs, inputs, ... }:
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
