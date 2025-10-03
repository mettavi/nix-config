{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
let
  cfg = config.nyx.shell.gh;
  # this is a secure way to read a sops-nix secret into an environment variable
  # see https://discourse.nixos.org/t/passing-secret-to-overlay-environment-variable/45795/2 for a discussion
  gh-wrapped = pkgs.writeShellScriptBin "gh" ''
    export GITHUB_TOKEN="$(cat ${
      config.sops.secrets."users/${config.home.username}/github_token".path
    })"
    ${pkgs.gh}/bin/gh $@
  '';
in
{
  # use the gh package to enable higher threshold for rate limiting to GH API (eg. nix flake update)
  options.nyx.shell.gh = {
    enable = mkOption {
      type = types.bool;
      default = true;
      description = "Install and configure the gh cli for github";
    };
  };

  config = mkIf cfg.enable {
    programs = {
      # NB: cannot use programs.gh home-manager module due to use of secure
      # "gh-wrapped" package (which conflicts with a pkgs.gh PATH symlink)
      git = {
        extraConfig = {
          credential = {
            # NB: this is a cross platform solution that doesn't require the osxkeychain option on darwin
            helper = "!gh auth git-credential";
          };
        };
      };
    };
    # install gh wrapper which will securely read the GITHUB_TOKEN variable for authentication with GitHub
    # this will call the gh git-credential helper when needed
    home.packages = [ gh-wrapped ];
  };
}
