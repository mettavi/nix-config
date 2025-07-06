{
  hostname,
  inputs,
  # pkgs,
  modulesPath,
  system,
  username,
  ...
}:
{
  imports = [
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  nixpkgs = {
    # Allow unfree packages
    config.allowUnfree = true;
    hostPlatform = "${system}";
  };

  nix = {
    extraOptions = ''
      warn-dirty = false
    '';
    settings = {
      experimental-features = [
        "nix-command"
        "flakes"
      ];
    };
  };

  # imports = [ ../../common/users/${username}/linux.nix ];

  users.users.${username} = {
    # set zsh as the user's default
    # shell = pkgs.zsh;
    # authorize remote login using ssh key
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII1n+RR5GUcqjFh7ypsw5bVOszWnZUa4VltzgK6eYGUv timotheos@salina"
    ];
  };

  # The Git revision of the top-level flake from which this configuration was built
  system.configurationRevision = inputs.self.rev or inputs.self.dirtyRev or null;

  # enable VMWare guest support
  virtualisation.vmware.guest.enable = true;

  # setup a file share from the host to the guest
  # fileSystems."/mnt/${hostname}/${username}" = {
  #   device = ".host:/${username}";
  #   fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
  #   options = [
  #     "umask=22"
  #     "uid=1000"
  #     "gid=100"
  #     "allow_other"
  #     "defaults"
  #     "auto_unmount"
  #   ];
  # };

  #  Use systemd for the bootloader
  boot.loader = {
    # the installation process is allowed to modify EFI boot variables
    efi.canTouchEfiVariables = true;
    # enable the systemd-boot EFI boot manager
    systemd-boot.enable = true;
  };

  networking.hostName = "${hostname}"; # Define your hostname.
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Allow NetworkManager to obtain an IP address if necessary
  networking.networkmanager.enable = true;

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n.defaultLocale = "en_GB.UTF-8";

  i18n.extraLocaleSettings = {
    LC_ADDRESS = "en_AU.UTF-8";
    LC_IDENTIFICATION = "en_AU.UTF-8";
    LC_MEASUREMENT = "en_AU.UTF-8";
    LC_MONETARY = "en_AU.UTF-8";
    LC_NAME = "en_AU.UTF-8";
    LC_NUMERIC = "en_AU.UTF-8";
    LC_PAPER = "en_AU.UTF-8";
    LC_TELEPHONE = "en_AU.UTF-8";
    LC_TIME = "en_AU.UTF-8";
  };

  # List services that you want to enable:

  # Enable the OpenSSH daemon.
  services = {
    openssh = {
      enable = true;
      # create a host key
      hostKeys = [
        {
          comment = "root@${hostname}";
          path = "/etc/ssh/ssh_${hostname}_ed25519_key";
          rounds = 100;
          type = "ed25519";
        }
      ];
    };
  };

  # Enable the X11 windowing system.
  services.xserver.enable = true;

  # Enable the XFCE Desktop Environment.
  services.xserver.displayManager.lightdm.enable = true;
  services.xserver.desktopManager.xfce.enable = true;

  # Configure keymap in X11
  services.xserver.xkb = {
    layout = "us";
    variant = "mac";
  };

  # Enable CUPS to print documents.
  services.printing.enable = true;

  # Enable sound with pipewire.
  services.pulseaudio.enable = false;
  security.rtkit.enable = true;
  services.pipewire = {
    enable = true;
    alsa.enable = true;
    alsa.support32Bit = true;
    pulse.enable = true;
    # If you want to use JACK applications, uncomment this
    #jack.enable = true;

    # use the example session manager (no others are packaged yet so this is enabled by default,
    # no need to redefine it in your config for now)
    #media-session.enable = true;
  };

  # Enable touchpad support (enabled default in most desktopManager).
  # services.xserver.libinput.enable = true;

  # Enable automatic login for the user.
  services.displayManager.autoLogin.enable = true;
  services.displayManager.autoLogin.user = "${username}";

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  # ];

  # Install and configure packages.
  # programs = {
  #   firefox = {
  #     enable = true;
  #   };
  # };

  # HOME MANAGER OPTIONS
  # home-manager.users.${username} = {
  # BUG: this is currently giving an error:
  #   xdg.desktopEntries = {
  #     mack-timotheos = {
  #       name = "mack-timotheos";
  #       comment = "Home directory for timeotheos on host mack";
  #       genericName = "File Share";
  #       icon = ../../modules/icons/org.xfce.thunar.png;
  #       type = "Directory";
  #     };
  #   };
  # };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "25.05"; # Did you read the comment?

}
