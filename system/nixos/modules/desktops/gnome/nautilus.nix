{ username, ... }:
{
  # override the nautilus .desktop file to change the default directory
  home-manager.users.${username} =
    { config, ... }:
    {
      xdg.desktopEntries = {
        "org.gnome.Nautilus" = {
          categories = [
            "GNOME"
            "GTK"
            "Utility"
            "Core"
            "FileManager"
          ];
          comment = "Access and organize files";
          # open the Downloads directory by default
          exec = "nautilus --new-window ${config.home.homeDirectory}/Downloads";
          icon = "org.gnome.Nautilus";
          mimeType = [
            "inode/directory"
            "application/x-7z-compressed"
            "application/x-7z-compressed-tar"
            "application/x-bzip"
            "application/x-bzip-compressed-tar"
            "application/x-compress"
            "application/x-compressed-tar"
            "application/x-cpio"
            "application/x-gzip"
            "application/x-lha"
            "application/x-lzip"
            "application/x-lzip-compressed-tar"
            "application/x-lzma"
            "application/x-lzma-compressed-tar"
            "application/x-tar"
            "application/x-tarz"
            "application/x-xar"
            "application/x-xz"
            "application/x-xz-compressed-tar"
            "application/zip"
            "application/gzip"
            "application/bzip2"
            "application/x-bzip2-compressed-tar"
            "application/vnd.rar"
            "application/zstd"
            "application/x-zstd-compressed-tar"
          ];
          name = "Files";
          startupNotify = true;
          terminal = false;
          type = "Application";
          actions = {
            "new-window" = {
              exec = "nautilus --new-window ${config.home.homeDirectory}/Downloads";
              name = "New Window";
            };
          };
          settings = {
            Keywords = "folder;manager;explore;disk;filesystem;nautilus;";
            DBusActivatable = "false";
            X-GNOME-UsesNotifications = "true";
            X-Purism-FormFactor = "Workstation;Mobile;";
          };
        };
      };
    };
}
