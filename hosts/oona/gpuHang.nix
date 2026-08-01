{
  pkgs,
  # username,
  ...
}:
let
  gpuHangCapture = pkgs.writeShellScriptBin "gpu-hang-capture" ''
    set -uo pipefail
    OUTDIR="$HOME/gpu-hang-logs"
    mkdir -p "$OUTDIR"
    TS=$(date +%Y%m%d-%H%M%S)
    OUT="$OUTDIR/gpu-hang-$TS.log"

    {
      echo "=== GPU hang capture: $TS ==="
      echo
      echo "--- Recent Xid / nvidia-modeset / pciehp kernel messages ---"
      journalctl -k -n 500 --no-pager 2>&1 | \
        grep -iE "xid|nvidia-modeset|pciehp|semaphore|blocked for more than"
      echo
      echo "--- nvidia-smi (5s timeout, in case GPU is already wedged) ---"
      timeout 5 nvidia-smi -q
      echo
      echo "--- lspci for nvidia device (5s timeout) ---"
      timeout 5 lspci -vvv -d 10de:
      echo
      echo "--- last 50 raw kernel log lines ---"
      journalctl -k -n 50 --no-pager
    } > "$OUT" 2>&1

    sync

    if grep -qi xid "$OUT"; then
      ${pkgs.libnotify}/bin/notify-send -u critical "GPU hang capture" "Xid error found — saved to $OUT"
    else
      ${pkgs.libnotify}/bin/notify-send "GPU hang capture" "Saved to $OUT (no Xid yet)"
    fi
  '';
in
{
  environment.systemPackages = [
    gpuHangCapture
    pkgs.libnotify
  ];

  home-manager.users.${username} = {
    dconf.settings = {
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom3" = {
        name = "GPU Hang Capture";
        command = "gpu-hang-capture";
        binding = "<Control><Alt>g";
      };
    };
  };
}
