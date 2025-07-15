#!/usr/bin/env bash
# See https://discourse.nixos.org/t/25274

prefix="$(greadlink --canonicalize -- "$(dirname -- "$0")/system/darwin/pkgs")"
nixpkgs="$(nix-instantiate --eval --expr '<nixpkgs>')"

exec nix-shell -vvvv "$nixpkgs/maintainers/scripts/update.nix" \
  --arg include-overlays '(import ./. { }).overlays' \
  --arg predicate "(
    let prefix = \"$prefix\"; prefixLen = builtins.stringLength prefix;
    in (_: p: (builtins.substring 0 prefixLen p.meta.position) == prefix)
  )"
