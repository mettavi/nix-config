{ pkgs, ... }:
{
  imports = [
    # Add your shared Neovim/shell/git Home Manager modules here, e.g.:
    # ../../home/shared/git.nix
    ../../home/shared/sops-home.nix
    ../../home/shared/nvim-wrap
  ];

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

  mettavi.shell.nvim-wrap.enable = true;
}
