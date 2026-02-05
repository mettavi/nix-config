#!/usr/bin/env bash

# Adapted from https://github.com/tmllull/BitwardenAutomatedBackup
# and https://github.com/binarypatrick/BitwardenBackup
# See https://github.com/dh024/Bitwarden_Export for a good INTERACTIVE export script

# set the user account to backup
USER="timotheos"

# load env vars required by script and bw binary
# shellcheck disable=SC1090,SC1091
source "$XDG_CONFIG_HOME/sops-nix/secrets/users/$USER/bitwarden.env"

TIMESTAMP=$(date "+%Y%m%d")
EXPORT_PATH="$HOME/backups/bitwarden"
LOG_PATH="$XDG_STATE_HOME/logs/bitwarden"
# EXPORT_PLAIN_FILE=bw_$TIMESTAMP.json
# EXPORT_ENCRYPTED_FILE=bw_enc_$TIMESTAMP.json
EXPORT_OPENSSL_FILE=bw_$TIMESTAMP.enc
# EXPORT_ORG_PLAIN_FILE=bw_org_$TIMESTAMP.json
# EXPORT_ORG_ENCRYPTED_FILE=bw_org_enc_$TIMESTAMP.json
EXPORT_ORG_OPENSSL_FILE=bw_org_$TIMESTAMP.enc

NOTIFICATION_EMAIL="timotheos.allen@gmail.com" # Email address used for notification if job fails
NOTIFICATION_EMAIL_SUBJECT="Bitwarden Backup Failed"
NOTIFICATION_EMAIL_BODY="The automated Bitwarden backup failed when trying to unlock the vault"

if [ ! -d "$EXPORT_PATH" ]; then
  echo "Folder '~/backups/bitwarden' does not exist. Creating it..."
  mkdir -p "$EXPORT_PATH"
else
  echo "Folder '~/backups/bitwarden' already exists."
fi

if [ ! -d "$LOG_PATH" ]; then
  echo "Folder 'logs/bitwarden' does not exist. Creating it..."
  mkdir -p "$LOG_PATH"
else
  echo "Folder 'logs/bitwarden' already exists."
fi

bw login --apikey
BW_SESSION=$(bw unlock --passwordenv BW_PASSWORD --raw)

if [ "$BW_SESSION" == "" ]; then
  echo "$NOTIFICATION_EMAIL_BODY" | mail -s "$NOTIFICATION_EMAIL_SUBJECT" "$NOTIFICATION_EMAIL"
  bw logout
  exit 1
fi

# Unencrypted export (not recommended)
#bw --raw --session $BW_SESSION export --format json --output $EXPORT_PATH/$EXPORT_PLAIN_FILE

# Encrypted export using encrypted_json from bitwarden
# echo "Export encrypted json using bitwarden format..."
# bw --raw --session $BW_SESSION export --format encrypted_json --password $BW_PASSWORD --output $EXPORT_PATH/$EXPORT_ENCRYPTED_FILE
# chmod 644 $EXPORT_PATH/$EXPORT_ENCRYPTED_FILE

# Encrypted export using openssl
echo "Export encrypted json using openssl..."
bw --raw --session "$BW_SESSION" export --format json | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -k "$OPENSSL_ENC_PASS" -out "$EXPORT_PATH"/"$EXPORT_OPENSSL_FILE" \
  >"$LOG_PATH" 2>&1

# ORGANIZATION
if [[ -n "$BW_ORG_ID" ]]; then
  # Unencrypted export (not recommended)
  #bw --raw --session $BW_SESSION export --organizationid $BW_ORG_ID --format json --output $EXPORT_PATH/$EXPORT_ORG_PLAIN_FILE

  # Encrypted export using encrypted_json from bitwarden
  # echo "Export encrypted json using bitwarden format..."
  # bw --raw --session $BW_SESSION export --organizationid $BW_ORG_ID --format encrypted_json --password $BW_PASSWORD --output $EXPORT_PATH/$EXPORT_ORG_ENCRYPTED_FILE
  # chmod 644 $EXPORT_PATH/$EXPORT_ORG_ENCRYPTED_FILE

  # Encrypted export using openssl
  echo "Export encrypted json using openssl..."
  bw --raw --session "$BW_SESSION" export --organizationid "$BW_ORG_ID" --format json | openssl enc -aes-256-cbc -pbkdf2 -iter 600000 -k "$OPENSSL_ENC_PASS" -out "$EXPORT_PATH"/"$EXPORT_ORG_OPENSSL_FILE"
else
  echo
  echo "No organizational vault defined."
fi

# Cleanup old files.
# Adjust the number of files to keep and days
# depending on your use case.
# NB: Once there are > 12 backups, "mtime +12w" will remove all backups older than 12 weeks
NUM_FILES=$(find "$EXPORT_PATH" -type f | wc -l)
if [ "$NUM_FILES" -gt 12 ]; then
  find "$EXPORT_PATH" -type f -mtime +12w -exec rm {} \;
fi

echo "Export completed!"
bw logout
