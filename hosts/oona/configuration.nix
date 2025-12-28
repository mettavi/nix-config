{
  config,
  pkgs,
  username,
  ...
}:

{
  imports = [
    # Include the results of the hardware scan.
    ./hardware-configuration.nix
  ];

  ########## SYSTEM ARCHITECTURE ###########

  # enable in-memory compressed devices and swap space
  zramSwap = {
    enable = true;
    algorithm = "zstd";
    # ensure zram is given priority over standard swap
    priority = 100;
  };

  services.xserver.videoDrivers = [
    "nvidia"
    # according to the wiki, this is unnecessary
    # "amdgpu"
  ];

  hardware.nvidia = {
    # Required for offloading to ensure the iGPU is used as the primary display
    modesetting.enable = true;
    dynamicBoost.enable = true;
    nvidiaSettings = true;
    powerManagement = {
      enable = true;
      finegrained = true;
    };
    open = true;
    package = config.boot.kernelPackages.nvidiaPackages.stable;
    prime = {
      offload = {
        enable = true;
        enableOffloadCmd = true;
      };
      nvidiaBusId = "PCI:100:0:0";
      amdgpuBusId = "PCI:101:0:0";
    };
  };

  hardware.enableRedistributableFirmware = true;

  # Use the systemd-boot EFI boot loader.
  boot.loader = {
    systemd-boot = {
      enable = true;
      # only keep 10 generations to prevent the boot partition from running out of space
      configurationLimit = 10;
      xbootldrMountPoint = "/boot";
    };
    efi = {
      canTouchEfiVariables = true;
      efiSysMountPoint = "/efi";
    };
  };

  boot.blacklistedKernelModules = [ "nouveau" ];

  # Use the cachyos kernel for the latest asus g14 kernel patches.
  boot.kernelPackages = pkgs.cachyosKernels.linuxPackages-cachyos-latest;

  # Configure network connections interactively with nmcli or nmtui.
  networking.networkmanager.enable = true;

  # Configure network proxy if necessary
  # networking.proxy.default = "http://user:password@proxy:port/";
  # networking.proxy.noProxy = "127.0.0.1,localhost,internal.domain";

  # console = {
  #   font = "Lat2-Terminus16";
  #   keyMap = "us";
  #   useXkbConfig = true; # use xkb.options in tty.
  # };

  services.supergfxd.enable = true;

  services = {
    asusd = {
      enable = true;
      enableUserService = true;
      # explicitly set to use the patched package
      package = pkgs.asusctl;
    };
  };

  # patch the asusctl package to include "aura" keyboard lighting definitions for this model laptop
  nixpkgs.overlays = [
    (final: prev: {
      asusctl = prev.asusctl.overrideAttrs (oldAttrs: {
        # Append your new patch to the existing list of patches
        patches = (oldAttrs.patches or [ ]) ++ [
          # Path to your patch file (it will be copied to the Nix store)
          ./aura_support_ga403w.patch
        ];
      });
    })
  ];

  # Configure keymap in X11
  # services.xserver.xkb.layout = "us";
  # services.xserver.xkb.options = "eurosign:e,caps:escape";

  # You can use https://search.nixos.org/ to find more packages (and options).
  environment.systemPackages = with pkgs; [
    firefox
    git
    vim # Do not forget to add an editor to edit configuration.nix! The Nano editor is also installed by default.
    wget
  ];

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

  mettavi.system = {
    # install and set up the gnome desktop
    gnome.enable = true;
    userConfig = {
      timotheos = {
        enable = true;
      };
    };
    services = {
      openssh.enable = true;
    };
    shell = {
      kanata.enable = true;
    };
  };

  home-manager.users.${username} = {
    home = {
      packages = with pkgs; [
        # Simple GPU Profile switcher for ASUS laptops using Supergfxctl
        gnomeExtensions.gpu-supergfxctl-switch
      ];
      stateVersion = "25.11";
    };
    dconf.settings = {
      # add custom keybindings for ASUS linux utilities
      "org/gnome/settings-daemon/plugins/media-keys" = {
        custom-keybindings = [
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1/"
          "/org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2/"
        ];
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom0" = {
        name = "ROG Control Center";
        command = "rog-control-center";
        # on the keyboard this is the M4 key
        binding = "Launch1";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom1" = {
        name = "Next Power Mode";
        command = "asusctl profile -n";
        # on the keyboard this is Fn-F5
        binding = "Launch4";
      };
      "org/gnome/settings-daemon/plugins/media-keys/custom-keybindings/custom2" = {
        name = "Next Aura Mode";
        command = "asusctl led-mode -n";
        # on the keyboard this is Fn-F4
        binding = "Launch3";
      };
      "org/gnome/shell" = {
        # `gnome-extensions list` for a list
        enabled-extensions = [
          "gpu-switcher-supergfxctl@chikobara.github.io"
        ];
      };
    };
    mettavi = {
      apps = {
        ghostty.enable = true;
      };
    };
  };

  # Copy the NixOS configuration file and link it from the resulting system
  # (/run/current-system/configuration.nix). This is useful in case you
  # accidentally delete configuration.nix.
  # system.copySystemConfiguration = true;

  # This option defines the first version of NixOS you have installed on this particular machine,
  # and is used to maintain compatibility with application data (e.g. databases) created on older NixOS versions.
  #
  # Most users should NEVER change this value after the initial install, for any reason,
  # even if you've upgraded your system to a new NixOS release.
  #
  # This value does NOT affect the Nixpkgs version your packages and OS are pulled from,
  # so changing it will NOT upgrade your system - see https://nixos.org/manual/nixos/stable/#sec-upgrading for how
  # to actually do that.
  #
  # This value being lower than the current NixOS release does NOT mean your system is
  # out of date, out of support, or vulnerable.
  #
  # Do NOT change this value unless you have manually inspected all the changes it would make to your configuration,
  # and migrated your data accordingly.
  #
  # For more information, see `man configuration.nix` or https://nixos.org/manual/nixos/stable/options#opt-system.stateVersion .
  system.stateVersion = "25.11"; # Did you read the comment?

}
