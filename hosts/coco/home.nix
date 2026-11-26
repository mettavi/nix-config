{ pkgs, ... }:
{
  imports = [
    ../../home/shared/sops-home.nix
    # Add your shared Neovim/shell/git Home Manager modules here, e.g.:
    # ../../home/shared/neovim.nix
    # ../../home/shared/git.nix
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
}
