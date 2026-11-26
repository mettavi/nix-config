{ pkgs, ... }:
{
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

  # Set your timezone (matches your current location)
  time.timeZone = "Asia/Colombo";

  # Match the Nix-on-Droid stateVersion from your initial bootstrap
  system.stateVersion = "24.05";
}
