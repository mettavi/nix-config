{
  # check nix-darwin/modules/system/activation-scripts.nix for allowed values for activationScripts.<name>
  system.activationScripts = {
    postActivation.text = ''
      # Enable remote login for the host (macos ssh server)
      # WORKAROUND: `systemsetup -f -setremotelogin on` requires `Full Disk Access`
      # permission for the Application calling it
      if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "Off" ]]; then
      launchctl load -w /System/Library/LaunchDaemons/ssh.plist
      fi
      # avoid a login/reboot to apply new settings after system activation (macOS)
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
    '';
  };
}
