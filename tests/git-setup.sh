#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
GIT_SETUP="$ROOT_DIR/bin/git-setup"
TEST_HOME="$(mktemp -d "${TMPDIR:-/tmp}/git-setup-test.XXXXXX")"

trap 'rm -rf "$TEST_HOME"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

HOME="$TEST_HOME" TERM=dumb "$GIT_SETUP" config > "$TEST_HOME/output"

for file in config delta.gitconfig gitattributes.global gitconfig_aliases gitignore.global shell_aliases; do
  [[ -f "$TEST_HOME/.config/git/$file" ]] || fail "missing generated file: $file"
done

[[ $(git config --file "$TEST_HOME/.config/git/config" --get user.name) == 'Roberto Flores' ]] || fail "default name was not generated"
[[ $(git config --file "$TEST_HOME/.config/git/config" --get user.email) == '25asab015@ujmd.edu.sv' ]] || fail "default email was not generated"
[[ $(git config --file "$TEST_HOME/.config/git/config" --get user.signingkey) == '~/.ssh/id_ed25519.pub' ]] || fail "SSH signing key was not generated"
grep -Fq 'Git Configuration Files' "$TEST_HOME/output" || fail "original configuration presentation was not shown"

printf 'PASS: restored git-setup configuration flow\n'
