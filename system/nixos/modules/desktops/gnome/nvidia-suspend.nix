# POTENTIAL FIX FOR PROBLEMS WITH NVIDIA GPU AFTER SYSTEM RESUME
# See https://wiki.nixos.org/wiki/NVIDIA
{
  config,
  lib,
  pkgs,
  ...
}:
with lib;
{
  config = mkIf config.mettavi.system.devices.nvidia.enable {
    # https://discourse.nixos.org/t/black-screen-after-suspend-hibernate-with-nvidia/54341/6
    # https://discourse.nixos.org/t/suspend-problem/54033/28
    systemd = {
      # Uncertain if this is still required or not.
      services.systemd-suspend.environment.SYSTEMD_SLEEP_FREEZE_USER_SESSIONS = "false";

      services."gnome-suspend" = {
        description = "suspend gnome shell";
        before = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-suspend.service"
          "nvidia-hibernate.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.procps}/bin/pkill -f -STOP ${pkgs.gnome-shell}/bin/gnome-shell";
        };
      };
      services."gnome-resume" = {
        description = "resume gnome shell";
        after = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
          "nvidia-resume.service"
        ];
        wantedBy = [
          "systemd-suspend.service"
          "systemd-hibernate.service"
        ];
        serviceConfig = {
          Type = "oneshot";
          ExecStart = "${pkgs.procps}/bin/pkill -f -CONT ${pkgs.gnome-shell}/bin/gnome-shell";
        };
      };
    };

    # https://discourse.nixos.org/t/black-screen-after-suspend-hibernate-with-nvidia/54341/23
    hardware.nvidia.powerManagement.enable = true;
  };
}
