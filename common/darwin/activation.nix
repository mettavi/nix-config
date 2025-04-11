{ pkgs, config, ... }:
{
  # check nix-darwin/modules/system/activation-scripts.nix for allowed values for activationScripts.<name>
  system.activationScripts = {
    # "activationScripts.userScript" 
    # nix-darwin runs this first to ensure /run/current-system exists before the main script is executed
    postUserActivation.text = ''
      # avoid a login/reboot to apply new settings after system activation (macOS)
      /System/Library/PrivateFrameworks/SystemAdministration.framework/Resources/activateSettings -u
      # Set keyboard navigation manually due to nix-darwin bug in system.defaults setting
      # See https://github.com/nix-darwin/nix-darwin/issues/1378
      # NB: This didn't work in keyboard.text or extraActivation.text
      defaults write NSGlobalDomain AppleKeyboardUIMode -int "2"
    '';
    # "activationScripts.script" (this is run after "userScript")
    applications.text =
      # install GUI apps with alias instead of symlink to show up in spotlight search
      let
        env = pkgs.buildEnv {
          name = "system-applications";
          paths = config.environment.systemPackages;
          pathsToLink = "/Applications";
        };
      in
      pkgs.lib.mkForce ''
        # Set up applications.
        echo "setting up /Applications..." >&2
        rm -rf /Applications/Nix\ Apps
        mkdir -p /Applications/Nix\ Apps
        find ${env}/Applications -maxdepth 1 -type l -exec readlink '{}' + |
        while read -r src; do
          app_name=$(basename "$src")
          echo "copying $src" >&2
          ${pkgs.mkalias}/bin/mkalias "$src" "/Applications/Nix Apps/$app_name"
        done
      '';

    extraActivation.text = ''
      # Enable remote login for the host (macos ssh server)
      # WORKAROUND: `systemsetup -f -setremotelogin on` requires `Full Disk Access`
      # permission for the Application calling it
      if [[ "$(systemsetup -getremotelogin | sed 's/Remote Login: //')" == "Off" ]]; then
        launchctl load -w /System/Library/LaunchDaemons/ssh.plist
      fi
    '';
  };
}
