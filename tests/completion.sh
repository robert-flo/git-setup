#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/git-setup-completion-test.XXXXXX")"

trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_output() {
  grep -Fqx -- "$2" "$1" || fail "missing completion entry: $2"
}

BASH_OUTPUT="$TEST_ROOT/bash-output"
bash -c '
  set -Eeuo pipefail
  source "$1/runtime/completion/git-setup.bash"
  COMP_WORDS=(git-setup "")
  COMP_CWORD=1
  _git_setup_completion
  printf "%s\n" "${COMPREPLY[@]}"
' _ "$ROOT_DIR" > "$BASH_OUTPUT"

for command in config verify setup test clean help; do
  require_output "$BASH_OUTPUT" "$command"
done
for alias in f --config -f v --verify -v s --setup -s t --test -t c --clean -c h --help -h; do
  require_output "$BASH_OUTPUT" "$alias"
done

bash -c '
  set -Eeuo pipefail
  source "$1/runtime/completion/git-setup.bash"
  COMP_WORDS=(git-setup verify "")
  COMP_CWORD=2
  _git_setup_completion
  printf "%s\n" "${COMPREPLY[@]}"
' _ "$ROOT_DIR" > "$TEST_ROOT/bash-options-output"
require_output "$TEST_ROOT/bash-options-output" '-h'
require_output "$TEST_ROOT/bash-options-output" '--help'

# Sourcing completion must only define completion state; it must not create or
# modify configuration files in the user's home directory.
mkdir -p "$TEST_ROOT/home"
HOME="$TEST_ROOT/home" XDG_CONFIG_HOME="$TEST_ROOT/home/.config" \
  bash -c 'source "$1/runtime/completion/git-setup.bash"' _ "$ROOT_DIR"
[[ ! -e $TEST_ROOT/home/.config ]] || fail 'Bash completion created configuration state'

if command -v zsh > /dev/null 2>&1; then
  zsh -n "$ROOT_DIR/runtime/completion/_git-setup"

  zsh -fc '
    CURRENT=2
    _describe() {
      print -r -- "describe:$1"
      print -rC1 -- "${(@P)2}"
    }
    _arguments() { print -r -- "arguments:$*"; }
    source "$1"
  ' _ "$ROOT_DIR/runtime/completion/_git-setup" > "$TEST_ROOT/zsh-commands-output"
  grep -Fqx 'describe:git-setup command' "$TEST_ROOT/zsh-commands-output" ||
    fail 'Zsh completion did not describe commands'
  grep -Fq 'verify:Review Git, SSH, GPG, GitHub, and generated configuration files.' \
    "$TEST_ROOT/zsh-commands-output" || fail 'Zsh completion did not describe verify'
  grep -Fq 'v:Review Git, SSH, GPG, GitHub, and generated configuration files.' \
    "$TEST_ROOT/zsh-commands-output" || fail 'Zsh completion did not describe aliases'

  zsh -fc '
    CURRENT=3
    words=(git-setup verify "")
    _describe() { print -r -- "unexpected describe call"; }
    _arguments() { print -r -- "arguments:$*"; }
    source "$1"
  ' _ "$ROOT_DIR/runtime/completion/_git-setup" > "$TEST_ROOT/zsh-options-output"
  grep -Fqx 'arguments:1:command:->command *:option:(-h --help)' \
    "$TEST_ROOT/zsh-options-output" || fail 'Zsh completion did not suggest help options'
else
  printf 'SKIP: zsh is unavailable; syntax check not run\n'
fi

printf 'PASS: Bash and Zsh completion contracts are valid\n'
