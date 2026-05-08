#!/usr/bin/env bash
set -euo pipefail

clear
echo "Name for this key (username or SUNET ID are solid identifiers):"
read -r NAME

echo "Email/comment for SSH key, e.g. leland@stanford.edu:"
read -r EMAIL

KEY="$HOME/.ssh/runpod_${NAME}_ed25519"
ENV_NAME="ENCRYPTED_PRIVATE_KEY_$(echo "$NAME" | tr '[:lower:]' '[:upper:]' | tr '-' '_')"

mkdir -p "$HOME/.ssh"
chmod 700 "$HOME/.ssh"

if [ -f "$KEY" ]; then
  echo "Key already exists at $KEY"
  echo "Reuse it? [y/N]"
  read -r REUSE
  if [ "$REUSE" != "y" ] && [ "$REUSE" != "Y" ]; then
    echo "Aborting."
    exit 1
  fi
else
  ssh-keygen -t ed25519 -f "$KEY" -C "$EMAIL" -N ""
fi

echo ""
echo "Add this PUBLIC key to GitHub deploy keys / SSH keys (https://github.com/settings/keys):"
echo "===================================================="
cat "${KEY}.pub"
echo "===================================================="
echo ""

echo "Press Enter after adding the public key to GitHub..."
read -r _

echo "Choose encryption password for RunPod env secret:"
base64 < "$KEY" | openssl enc -aes-256-cbc -pbkdf2 -salt -a > "${KEY}.enc"

echo ""
echo "Paste this into RunPod encrypted env vars:"
echo "===================================================="
printf '%s=' "$ENV_NAME"
tr -d '\n' < "${KEY}.enc"
printf '\n'
echo "===================================================="