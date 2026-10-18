{
  config,
  hostname,
  lib,
  secrets_path,
  username,
  ...
}:
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

  cfg = config.mettavi.system.services.syncthing;
  self = cfg.deviceName;
  selfUntrusted = cfg.devices.${self}.untrusted or false;
  isUntrusted = d: cfg.devices.${d}.untrusted or false;

  myFolders = filterAttrs (_: f: elem self f.devices) cfg.folders;
  otherDevices = filterAttrs (n: _: n != self) cfg.devices;

  cert_pem = "users/${username}/syncthing/st_${hostname}_cert.pem";
  key_pem = "users/${username}/syncthing/st_${hostname}_key.pem";
  syncthingSecrets.sopsFile = "${secrets_path}/secrets/apps/syncthing.yaml";
in
{
  options.mettavi.system.services.syncthing = {
    enable = mkEnableOption "Set up a declarative Syncthing network";

    deviceName = mkOption {
      type = types.str;
      default = hostname;
      description = "The local hostname to be excluded from the list of remote devices";
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
            devices = mkOption {
              type = types.listOf types.str;
              description = "The devices this folder is shared with";
            };
            path = mkOption {
              type = types.nullOr types.str;
              default = null;
              description = "The default path for a shared folder";
            };
            paths = mkOption {
              type = types.attrsOf types.str;
              default = { };
              description = "An attribute set with a device and its non-default folder path";
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
        message = "mettavi.system.services.syncthing.deviceName '${self}' is not in mettavi.system.services.syncthing.devices.";
      }
    ]
    ++ mapAttrsToList (name: f: {
      assertion = all (d: cfg.devices ? ${d}) f.devices;
      message = "mettavi.system.services.syncthing.folders.${name} references an undefined device.";
    }) cfg.folders
    ++ mapAttrsToList (name: f: {
      assertion = all (d: elem d f.devices) (builtins.attrNames f.paths);
      message = "mettavi.system.services.syncthing.folders.${name}.paths has a key that is not in its devices list.";
    }) cfg.folders
    ++ mapAttrsToList (name: f: {
      assertion = selfUntrusted || !(any isUntrusted f.devices) || cfg.encryptionPasswordFiles ? ${name};
      message = "Set mettavi.system.services.syncthing.encryptionPasswordFiles.${name} on this host.";
    }) myFolders;

    services.syncthing = {
      enable = true;
      cert = "${config.sops.secrets.${cert_pem}.path}";
      key = "${config.sops.secrets.${key_pem}.path}";
      # Whether to delete the devices which are not configured via the devices option
      overrideDevices = true;
      # Whether to delete the folders which are not configured via the folders option
      overrideFolders = true;
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
    sops.secrets = {
      ${cert_pem} = syncthingSecrets;
      ${key_pem} = syncthingSecrets;
      "${gui_pw}" = syncthingSecrets;
      # see note above
      # "${gui_apikey}" = syncthingSecrets;
    };
  };
}
