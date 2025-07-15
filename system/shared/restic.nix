{ pkgs, ... }:
{
  # restic_1drive = pkgs.restic.overrideAttrs (oldAttrs: {
  #   postInstall =
  #     (oldAttrs.postInstall or "")
  #     + ''
  #       export RESTIC_REPOSITORY="rclone:onedrive:calibre";
  #       # initialise calibre repo if necessary
  #       if ! restic cat config > /dev/null 2>&1; then
  #         restic -r rclone:ondedrive:calibre init;
  #     '';
  # });

  environment.systemPackages = with pkgs; [
    restic # Backup with delta transfers (eg. to cloud storage via rclone)
    resticprofile # Configuration manager for restic
  ];
}
