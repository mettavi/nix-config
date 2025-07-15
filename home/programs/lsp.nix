{ pkgs, ... }:
{
  home.packages = with pkgs; [
    bash-language-server
    lua-language-server
    nixd # nix language server
    nixfmt-rfc-style
    prettier
    shfmt
    stylua
    taplo
    typescript-language-server
    yaml-language-server
    yamlfmt
    yamllint
  ];
}
