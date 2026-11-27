{ pkgs, ... }:
{
  # Use Nix-on-Droid's compatible Nix version to avoid PTY permission errors in proot
  nix.package = pkgs.nixVersions.nix_2_31;
  # (If nix_2_24 still hits the PTY error or isn't in 26.05, use Nix-on-Droid's own pinned Nix:
  # nix.package = inputs.nix-on-droid.packages.${pkgs.stdenv.hostPlatform.system}.nix; )

  # Essential system packages available in the base environment
  environment.packages = with pkgs; [
    git
    vim
    openssh
    age
    sops
  ];

  # Backup files instead of failing on activation collisions
  environment.etcBackupExtension = ".bak";

terminal.font = "${pkgs.nerd-fonts.jetbrains-mono}/share/fonts/truetype/NerdFonts/JetBrainsMono/JetBrainsMonoNerdFont-Regular.ttf";

  # Set your timezone (matches your current location)
  time.timeZone = "Asia/Colombo";

  # Match the Nix-on-Droid stateVersion from your initial bootstrap
  system.stateVersion = "24.05";
}
