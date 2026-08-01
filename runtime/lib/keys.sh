#!/usr/bin/env bash

# Key lookup capability shared by setup and verification.
get_gpg_key_id() {
  local key_id=""

  # Try by name
  key_id=$(gpg --list-secret-keys --keyid-format SHORT "$USER_NAME" 2> /dev/null | grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2 || true)

  # Try by email
  if [[ -z $key_id ]]; then
    key_id=$(gpg --list-secret-keys --keyid-format SHORT "$USER_EMAIL" 2> /dev/null | grep "^sec" | head -1 | awk '{print $2}' | cut -d'/' -f2 || true)
  fi

  # Try any RSA key
  if [[ -z $key_id ]]; then
    key_id=$(gpg --list-secret-keys --keyid-format SHORT 2> /dev/null | grep "^sec" | grep "rsa4096" | head -1 | awk '{print $2}' | cut -d'/' -f2 || true)
  fi

  echo "$key_id"
}
