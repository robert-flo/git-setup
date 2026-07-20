#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_SETUP="$ROOT_DIR/bin/git-setup"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/git-setup-test.XXXXXX")"
TEST_BIN="$TEST_ROOT/bin"
DEFAULT_HOME="$TEST_ROOT/default-home"
CUSTOM_HOME="$TEST_ROOT/custom-home"

trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_file() {
  [[ -f $1 ]] || fail "missing file: $1"
}

require_output() {
  grep -Fq "$2" "$1" || fail "missing output: $2"
}

run_setup() {
  local home="$1"
  shift

  HOME="$home" TERM=dumb PATH="$TEST_BIN:$PATH" "$GIT_SETUP" "$@"
}

mkdir -p "$TEST_BIN" "$DEFAULT_HOME" "$CUSTOM_HOME"

# Keep tests offline and prevent access to the developer's GitHub, SSH, or GPG
# sessions. The commands are present so `verify` exercises its complete flow.
for command in gh ssh ssh-add pgrep; do
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' > "$TEST_BIN/$command"
  chmod +x "$TEST_BIN/$command"
done

printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "${1:-}" in' \
  '  --list-secret-keys) exit 0 ;;' \
  '  --clearsign) cat; exit 0 ;;' \
  'esac' \
  'exit 0' > "$TEST_BIN/gpg"
chmod +x "$TEST_BIN/gpg"

generated_files=(
  config
  delta.gitconfig
  gitattributes.global
  gitconfig_aliases
  gitignore.global
  shell_aliases
)

# Default generation copies each managed template and writes the Git identity.
run_setup "$DEFAULT_HOME" config > "$TEST_ROOT/default-config-output"
for file in "${generated_files[@]}"; do
  require_file "$DEFAULT_HOME/.config/git/$file"
done

default_config="$DEFAULT_HOME/.config/git/config"
[[ $(git config --file "$default_config" --get user.name) == 'Roberto Flores' ]] || fail 'default name was not generated'
[[ $(git config --file "$default_config" --get user.email) == '25asab015@ujmd.edu.sv' ]] || fail 'default email was not generated'
[[ $(git config --file "$default_config" --get user.signingkey) == '~/.ssh/id_ed25519.pub' ]] || fail 'SSH signing key was not generated'
[[ $(git config --file "$default_config" --get gpg.format) == 'ssh' ]] || fail 'SSH signing format was not generated'
require_output "$TEST_ROOT/default-config-output" 'Git Configuration Files'
require_output "$TEST_ROOT/default-config-output" 'Created:'
require_output "$TEST_ROOT/default-config-output" 'Persistent Git customization:'

# A subsequent run refreshes managed files but preserves the local override.
printf '[user]\n\tname = Local Override\n' > "$DEFAULT_HOME/.config/git/gitconfig.local"
run_setup "$DEFAULT_HOME" config > "$TEST_ROOT/updated-config-output"
require_output "$TEST_ROOT/updated-config-output" 'Updated:'
require_file "$DEFAULT_HOME/.config/git/gitconfig.local"
grep -Fq 'Local Override' "$DEFAULT_HOME/.config/git/gitconfig.local" || fail 'gitconfig.local was overwritten'

# NAME and EMAIL provide a non-interactive identity for automation.
NAME='Ada Lovelace' EMAIL='ada@example.com' run_setup "$CUSTOM_HOME" config > "$TEST_ROOT/custom-config-output"
custom_config="$CUSTOM_HOME/.config/git/config"
[[ $(git config --file "$custom_config" --get user.name) == 'Ada Lovelace' ]] || fail 'NAME was not generated'
[[ $(git config --file "$custom_config" --get user.email) == 'ada@example.com' ]] || fail 'EMAIL was not generated'

# Verification reports its own section for all generated files without relying
# on the workstation's credentials or keyring.
run_setup "$CUSTOM_HOME" verify > "$TEST_ROOT/verify-output" || true
require_output "$TEST_ROOT/verify-output" 'Generated Git Configuration Files'
for file in "${generated_files[@]}"; do
  require_output "$TEST_ROOT/verify-output" "Found: ~/.config/git/$file"
done

# Clean must disclose the managed files and remain non-destructive until 'yes'.
printf 'no\n' | run_setup "$CUSTOM_HOME" clean > "$TEST_ROOT/clean-output"
require_output "$TEST_ROOT/clean-output" 'Git Configuration:'
require_output "$TEST_ROOT/clean-output" '~/.config/git/config'
require_output "$TEST_ROOT/clean-output" 'gitconfig.local will be preserved'
require_output "$TEST_ROOT/clean-output" 'Cancelled'
require_file "$CUSTOM_HOME/.config/git/config"

# Invoking without arguments remains the original interactive RaVN menu.
printf 'q\n' | run_setup "$CUSTOM_HOME" > "$TEST_ROOT/menu-output"
require_output "$TEST_ROOT/menu-output" 'Git + GitHub + GPG Configuration for Arch Linux'
require_output "$TEST_ROOT/menu-output" 'Choose an action'
require_output "$TEST_ROOT/menu-output" 'Verify current configuration'

printf 'PASS: git-setup managed configuration and interactive workflow\n'
