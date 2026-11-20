{
  config,
  hostname,
  inputs,
  lib,
  pkgs,
  secrets_path,
  username,
  ...
}:

let
  cfg = config.mettavi.system.services.bookOrbit;
  unstableSrc = inputs.nixpkgs;
  unstablePkgs = import unstableSrc {
    inherit (pkgs.stdenv.hostPlatform) system;
    config.allowUnfree = true;
  };
  inherit (lib)
    mkEnableOption
    mkForce
    mkIf
    mkOption
    ;
  inherit (lib.types) bool str;
  updateOpfScript =
    pkgs.writers.writePython3Bin "update-bookorbit-opf" { } # py
      ''
        import glob
        import html
        import json
        import re

        # Move <dc:subject> into bookorbit:tags and remove duplicate Genres
        STRIP_GENRES = True

        updated = 0
        for path in glob.glob('/srv/media/ebooks/**/metadata.opf', recursive=True):
            with open(path, 'r', encoding='utf-8') as f:
                content = f.read()

            changed = False
            new_tags_xml = []

            # 1. Extract #pagecount / #pages and write bookorbit:page_count
            m = re.search(
                r'<meta\s+name="calibre:user_metadata:'
                r'#(?:pagecount|page_count|pages)"\s+content="([^"]+)"',
                content,
            )
            if m and 'bookorbit:page_count' not in content:
                try:
                    meta_json = json.loads(html.unescape(m.group(1)))
                    pages = meta_json.get('#value#')
                    if isinstance(pages, int) and pages > 0:
                        tag = (
                            f'        <meta name="bookorbit:page_count"'
                            f' content="{pages}"/>'
                        )
                        new_tags_xml.append(tag)
                except Exception:
                    pass

            # 2. Extract <dc:subject> tags and write bookorbit:tags
            subjects = [
                html.unescape(s.strip())
                for s in re.findall(
                    r'<dc:subject>(.*?)</dc:subject>', content, flags=re.DOTALL
                )
                if s.strip()
            ]
            if subjects and 'bookorbit:tags' not in content:
                joined = html.escape(', '.join(subjects), quote=True)
                tag = f'        <meta name="bookorbit:tags" content="{joined}"/>'
                new_tags_xml.append(tag)

            if new_tags_xml:
                inject = '\n'.join(new_tags_xml) + '\n    </metadata>'
                content = content.replace('</metadata>', inject, 1)
                changed = True

            # 3. Strip <dc:subject> so BookOrbit doesn't duplicate Tags in Genres
            if STRIP_GENRES and '<dc:subject>' in content:
                content = re.sub(
                    r'\s*<dc:subject>.*?</dc:subject>', ''', content, flags=re.DOTALL
                )
                changed = True

            if changed:
                with open(path, 'w', encoding='utf-8') as f:
                    f.write(content)
                updated += 1

        print(f"Updated {updated} metadata.opf files.")
      '';
in
{
  # Import the bookorbit NixOS module directly from the unstable input
  imports = [
    "${unstableSrc}/nixos/modules/services/web-apps/bookorbit.nix"
  ];

  options.mettavi.system.services.bookOrbit = {
    enable = mkEnableOption "Install and set up the BookOrbit self-hosted library platform";
    appUrl = mkOption {
      type = str;
      default = "http://localhost:3000";
      description = "The url where the app will be hosted";
    };
    openFwPort = mkOption {
      type = bool;
      default = false;
      description = "Whether to open the port in the firewall";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ updateOpfScript ];

    # NB:use 'optionalAttrs'; 'mkIf' doesn’t stop “option does not exist” errors
    services.bookorbit = mkIf cfg.enable {
      enable = true;
      # Use the unstable package so it matches the unstable module
      package = unstablePkgs.bookorbit;
      # POSTGRES_USER and POSTGRES_DB default to "bookorbit"
      createDatabaseLocally = true;
      # Environment variables to pass to the BookOrbit service.
      # See <https://bookorbit.app/installation.html#configuration> for available options.
      environment = {
        # Data storage directory.
        APP_DATA_PATH = "/var/lib/bookorbit";
        # The address you will use to open BookOrbit.
        # Direct LAN access: http://your-server-ip:3000
        # Behind a reverse proxy with a domain: https://books.example.com
        # Must match the public domain configured in your Pangolin dashboard
        APP_URL = cfg.appUrl;
        LOG_LEVEL = "info";
        # TCP port for the BookOrbit server.
        PORT = 3000;
        # Required when running behind a reverse proxy like Traefik/Pangolin
        TRUST_PROXY = "true";
      };
      environmentFile = config.sops.secrets."users/${username}/bookorbit-${hostname}.env".path;
      user = "bookorbit";
      group = "bookorbit";
      # Keep false if Pangolin/Newt reaches this VPS over a private WireGuard tunnel.
      # Set to true ONLY if Pangolin connects to this VPS's public IP directly.
      openFirewall = cfg.openFwPort;
    };

    sops.secrets."users/${username}/bookorbit-${hostname}.env" = {
      sopsFile = "${secrets_path}/secrets/apps/bookorbit.yaml";
      mode = "0600";
      owner = "bookorbit";
      group = "bookorbit";
    };

    # Allow admin user (via bookorbit group) to browse files BookOrbit organizes
    systemd.services.bookorbit.serviceConfig.UMask = mkForce "0007";

    # let NixOS enforce the directory structure and permissions on every rebuild
    systemd.tmpfiles.rules = [
      "d /srv/media 2770 bookorbit bookorbit -"
      "d /srv/media/audiobooks 2770 bookorbit bookorbit -"
      "d /srv/media/ebooks 2770 bookorbit bookorbit -"
    ];

    # add the admin user to the bookorbit group
    users.users.${username}.extraGroups = [ "bookorbit" ];
  };
}
