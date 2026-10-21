{
  config,
  hostname,
  inputs,
  lib,
  secrets_path,
  username,
  ...
}:
let
  inherit (lib)
    mkOption
    mkEnableOption
    mkMerge
    mkIf
    types
    filterAttrs
    mapAttrs
    mapAttrs'
    mapAttrsToList
    nameValuePair
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

  # secrets
  cert_pem = "users/${username}/syncthing/st_${hostname}_cert.pem";
  key_pem = "users/${username}/syncthing/st_${hostname}_key.pem";
  web_pw = "users/${username}/syncthing/st_${hostname}_web.key";
  syncthingSecrets.sopsFile = "${secrets_path}/secrets/apps/syncthing.yaml";
in
{
  imports = [ ./topology.nix ];

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

  config = mkMerge [
    (mkIf cfg.enable {
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
        guiAddress = "127.0.0.1:8384";
        # the module will create the bcrypt hash of the password itself
        guiPasswordFile = "${config.sops.secrets.${web_pw}.path}";
        # Whether to delete the devices which are not configured via the devices option
        overrideDevices = true;
        # Whether to delete the folders which are not configured via the folders option
        overrideFolders = true;
        settings = {
          devices = mapAttrs (_: d: { inherit (d) id addresses; }) cfg.devices;

          folders = mapAttrs (
            name: f:
            let
              p = f.paths.${self} or f.path;
              # if null, 'path' falls back to <dataDir>/<folderName>
              fallback = "${config.services.syncthing.dataDir}/${name}";
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
            // {
              path = if p != null then p else fallback;
            }
            // optionalAttrs selfUntrusted { type = "receiveencrypted"; }
          ) myFolders;
          gui.user = "${inputs.secrets.username.primary}";
          options = {
            # Whether to send announcements to the local LAN
            localAnnounceEnabled = true;
            # do not enable anonymous usage reporting
            urAccepted = -1;
          };
        };
      };

      sops.secrets = {
        ${cert_pem} = syncthingSecrets;
        ${key_pem} = syncthingSecrets;
        ${web_pw} = {
          owner = config.services.syncthing.user;
          sopsFile = "${secrets_path}/secrets/apps/syncthing.yaml";
        };
      };
    })
    (mkIf (cfg.enable && !selfUntrusted) (
      let
        needsPassword = filterAttrs (_: f: any isUntrusted f.devices) myFolders;
      in
      {
        sops.secrets = mapAttrs' (
          name: _:
          nameValuePair "users/${username}/syncthing/st_${name}.key" {
            owner = config.services.syncthing.user;
            sopsFile = "${secrets_path}/secrets/apps/syncthing.yaml";
          }
        ) needsPassword;

        mettavi.system.services.syncthing.encryptionPasswordFiles = mapAttrs (
          name: _: config.sops.secrets."users/${username}/syncthing/st_${name}.key".path
        ) needsPassword;
      }
    ))
  ];
}
