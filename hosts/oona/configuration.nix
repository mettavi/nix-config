{
  config,
  hostname,
  modulesPath,
  pkgs,
  username,
  ...
}:
let
  df_sh = config.home-manager.users.${username}.nyx.modules.shell.default;
in
{
  imports = [
    # imports for initial install with nixos-anywhere and disko
    # subsequently the disko config will configure fstab
    (modulesPath + "/installer/scan/not-detected.nix")
    (modulesPath + "/profiles/qemu-guest.nix")
    ./disk-config.nix
  ];

  ########## IMPORTANT SETTINGS ###########

  # SETUP INITIAL ACCESS
  users.users.${username} = {
    # authorize remote login using ssh key(s)
    openssh.authorizedKeys.keys = [
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIGuMPsZDaz4CJpc9HH6hMdP1zLxJIp7gt7No/e/wvKgb timotheos@mack"
      "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAII1n+RR5GUcqjFh7ypsw5bVOszWnZUa4VltzgK6eYGUv timotheos@salina"
    ];
    # assign the user's default shell (requires also setting "programs.${shell}.enable")
    shell = pkgs.${df_sh};
  };
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

  # "oona" is a vmware guest running on darwin host "mack"
  # enable VMWare guest support
  virtualisation.vmware.guest.enable = true;

  # setup a file share from the host to the guest
  # NB: also requires manual set up on the darwin host
  fileSystems."/mnt/mack/${username}" = {
    # this folder must be exported on the host beforehand
    device = ".host:/${username}";
    fsType = "fuse./run/current-system/sw/bin/vmhgfs-fuse";
    mountPoint = "/mnt/mack/${username}";
    options = [
      "umask=22"
      "uid=1000"
      "gid=100"
      "allow_other"
      "defaults"
      "auto_unmount"
      # prevents emergency mode upon misconfiguration
      "nofail"
    ];
  };

  # enable automatic login for the user.
  services.displayManager = {
    autoLogin = {
      enable = true;
      user = "${username}";
    };
  };

  ########## SYSTEM ARCHITECTURE ###########

  # enable in-memory compressed devices and swap space
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    priority = 100;
  };

  boot.kernel.sysctl = {
    # default is 60
    "vm.swappiness" = 90;
  };

  # Use systemd for the bootloader
  boot.loader = {
    # the installation process is allowed to modify EFI boot variables
    efi.canTouchEfiVariables = true;
    # enable the systemd-boot EFI boot manager
    systemd-boot.enable = true;
  };

  services = {
    xserver = {
      # Enable the X11 windowing system.
      enable = true;
      # Select the login manager
      displayManager = {
        lightdm = {
          enable = true;
        };
      };
      desktopManager = {
        xfce = {
          enable = true;
        };
      };
      # Configure keymap in X11
      xkb = {
        layout = "us";
        variant = "mac";
      };
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion).
  system.stateVersion = "25.05"; # Did you read the comment?

  ######### SYSTEM SETTINGS ##########

  networking = {
    networkmanager = {
      enable = true; # Allow NetworkManager to obtain an IP address if necessary
    };
  };
  # networking.wireless.enable = true;  # Enables wireless support via wpa_supplicant.
  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # Open ports in the firewall.
  # networking.firewall.allowedTCPPorts = [ ... ];
  # networking.firewall.allowedUDPPorts = [ ... ];
  # Or disable the firewall altogether.
  # networking.firewall.enable = false;

  # Set your time zone.
  time.timeZone = "Australia/Melbourne";

  # Select internationalisation properties.
  i18n = {
    defaultLocale = "en_GB.UTF-8";
    extraLocaleSettings = {
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
  };

  ######## SYSTEM SERVICES ##########

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

  # List packages installed in system profile. To search, run:
  # $ nix search wget
  # environment.systemPackages = with pkgs; [
  # ];

  # HOME MANAGER OPTIONS
  home-manager.users.${username} = {
    home = {
      # https://nixos.wiki/wiki/FAQ/When_do_I_update_stateVersion
      stateVersion = "25.05";
    };
    nyx.modules = {
      desktop = {
        # configure the XFCE desktop
        xfce.enable = true;
      };
    };
    xdg.desktopEntries = {
      # add a desktop shortcut to the host share
      mack-timotheos = {
        name = "mack-timotheos";
        comment = "Home directory for timotheos on host mack";
        icon = "folder";
        type = "Application";
        # this is an XFCE-specific command
        exec = "exo-open --working-directory /mnt/mack/timotheos --launch FileManager";
      };
    };
  };

  # Some programs need SUID wrappers, can be configured further or are
  # started in user sessions.
  # programs.mtr.enable = true;
  # programs.gnupg.agent = {
  #   enable = true;
  #   enableSSHSupport = true;
  # };
}
