#!/usr/bin/env bash

source /Users/timotheos/.config/sops-nix/secrets/users/timotheos/bitwarden.env

OUTNAME=$(basename "$1" .enc).json
openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -k "$OPENSSL_ENC_PASS" -d -nopad -in "$1" -out "$OUTNAME"
