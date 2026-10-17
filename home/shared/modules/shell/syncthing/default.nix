{ config, lib, ... }:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkIf
    types
    filterAttrs
    mapAttrs
    mapAttrsToList
    optionalAttrs
    elem
    all
    any
    filter
    ;

  cfg = config.my.syncthing;
  self = cfg.deviceName;
  selfUntrusted = cfg.devices.${self}.untrusted or false;
  isUntrusted = d: cfg.devices.${d}.untrusted or false;

  myFolders = filterAttrs (_: f: elem self f.devices) cfg.folders;
  otherDevices = filterAttrs (n: _: n != self) cfg.devices;
in
{
  options.my.syncthing = {
    enable = mkEnableOption "declarative Syncthing network";

    deviceName = mkOption {
      type = types.str;
      default = config.networking.hostName;
    };

    devices = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            id = mkOption { type = types.str; };
            addresses = mkOption {
              type = types.listOf types.str;
              default = [ "dynamic" ];
            };
            untrusted = mkOption {
              type = types.bool;
              default = false;
              description = "Holds only encrypted data (receiveencrypted).";
            };
          };
        }
      );
    };

    folders = mkOption {
      default = { };
      type = types.attrsOf (
        types.submodule {
          options = {
            devices = mkOption { type = types.listOf types.str; };
            path = mkOption {
              type = types.nullOr types.str;
              default = null;
            };
            paths = mkOption {
              type = types.attrsOf types.str;
              default = { };
            };
            settings = mkOption {
              type = types.attrs;
              default = { };
            };
          };
        }
      );
    };

    # Per-host secret paths (e.g. sops-nix / agenix), set only on trusted hosts.
    encryptionPasswordFiles = mkOption {
      type = types.attrsOf types.str; # str, not path: must not be copied to the store
      default = { };
      description = "Folder name -> runtime path of the password used for untrusted peers.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.devices ? ${self};
        message = "my.syncthing.deviceName '${self}' is not in my.syncthing.devices.";
      }
    ]
    ++ mapAttrsToList (name: f: {
      assertion = all (d: cfg.devices ? ${d}) f.devices;
      message = "my.syncthing.folders.${name} references an undefined device.";
    }) cfg.folders
    ++ mapAttrsToList (name: f: {
      assertion = selfUntrusted || !(any isUntrusted f.devices) || cfg.encryptionPasswordFiles ? ${name};
      message = "Set my.syncthing.encryptionPasswordFiles.${name} on this host.";
    }) myFolders;

    services.syncthing = {
      enable = true;
      settings = {
        devices = mapAttrs (_: d: { inherit (d) id addresses; }) otherDevices;

        folders = mapAttrs (
          name: f:
          let
            p = f.paths.${self} or f.path;
            mkPeer =
              d:
              if isUntrusted d then
                {
                  name = d;
                  encryptionPasswordFile = cfg.encryptionPasswordFiles.${name};
                }
              else
                d;
          in
          f.settings
          // {
            devices = map mkPeer (filter (d: d != self) f.devices);
          }
          // optionalAttrs (p != null) { path = p; }
          // optionalAttrs selfUntrusted { type = "receiveencrypted"; }
        ) myFolders;
      };
    };
  };
}
