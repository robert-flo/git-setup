#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
# The supported development entry point is the root dispatcher, not an
# implementation file under bin/.
GIT_SETUP="$ROOT_DIR/git-setup"
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

  (
    cd "$TEST_ROOT"
    HOME="$home" XDG_CONFIG_HOME="$home/.config" TERM=dumb PATH="$TEST_BIN:$PATH" "$GIT_SETUP" "$@"
  )
}

mkdir -p "$TEST_BIN" "$DEFAULT_HOME" "$CUSTOM_HOME"

# Keep tests offline and prevent access to the developer's GitHub, SSH, or GPG
# sessions. The commands are present so `verify` exercises its complete flow.
for command in gh ssh ssh-add pgrep delta; do
  printf '%s\n' '#!/usr/bin/env bash' 'exit 1' > "$TEST_BIN/$command"
  chmod +x "$TEST_BIN/$command"
done

# shellcheck disable=SC2016 # The stub must receive a literal parameter expansion.
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'case "${1:-}" in' \
  '  --list-secret-keys) exit 0 ;;' \
  '  --clearsign) cat; exit 0 ;;' \
  'esac' \
  'exit 0' > "$TEST_BIN/gpg"
chmod +x "$TEST_BIN/gpg"

# Missing dependencies stop the public command before it does any work. The
# detected package manager is guidance only: neither it nor sudo may run.
MISSING_DEPENDENCY_BIN="$TEST_ROOT/missing-dependency-bin"
DEPENDENCY_EXECUTION_MARKER="$TEST_ROOT/dependency-command-executed"
MISSING_DEPENDENCY_HOME="$TEST_ROOT/missing-dependency-home"
mkdir -p "$MISSING_DEPENDENCY_BIN" "$MISSING_DEPENDENCY_HOME"

for command in bash chmod cp dirname git mkdir realpath gpg ssh-keygen; do
  ln -s "$(command -v "$command")" "$MISSING_DEPENDENCY_BIN/$command"
done

printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$MISSING_DEPENDENCY_BIN/delta"
# shellcheck disable=SC2016 # The generated stubs expand these values when run.
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "executed: %s\n" "${0##*/}" >> "$DEPENDENCY_EXECUTION_MARKER"' \
  'exit 99' > "$MISSING_DEPENDENCY_BIN/apt"
cp "$MISSING_DEPENDENCY_BIN/apt" "$MISSING_DEPENDENCY_BIN/sudo"
chmod +x "$MISSING_DEPENDENCY_BIN/delta" "$MISSING_DEPENDENCY_BIN/apt" "$MISSING_DEPENDENCY_BIN/sudo"

missing_dependency_status=0
PATH="$MISSING_DEPENDENCY_BIN" \
  HOME="$MISSING_DEPENDENCY_HOME" \
  XDG_CONFIG_HOME="$MISSING_DEPENDENCY_HOME/.config" \
  TERM=dumb \
  DEPENDENCY_EXECUTION_MARKER="$DEPENDENCY_EXECUTION_MARKER" \
  "$GIT_SETUP" config > "$TEST_ROOT/missing-dependency-output" 2>&1 || missing_dependency_status=$?

((missing_dependency_status != 0)) || fail 'missing dependency did not stop git-setup'
require_output "$TEST_ROOT/missing-dependency-output" 'gh not found'
require_output "$TEST_ROOT/missing-dependency-output" 'Ubuntu/Debian (detected):'
require_output "$TEST_ROOT/missing-dependency-output" 'sudo apt install git gh gnupg openssh-client git-delta'
require_output "$TEST_ROOT/missing-dependency-output" 'Arch Linux:'
require_output "$TEST_ROOT/missing-dependency-output" 'sudo pacman -S --needed git github-cli gnupg openssh git-delta'
require_output "$TEST_ROOT/missing-dependency-output" 'Fedora:'
require_output "$TEST_ROOT/missing-dependency-output" 'sudo dnf install git gh gnupg2 openssh-clients git-delta'
[[ ! -e $DEPENDENCY_EXECUTION_MARKER ]] || fail 'dependency guidance executed a privileged package command'
[[ ! -e $MISSING_DEPENDENCY_HOME/.config/git/config ]] || fail 'missing dependency allowed configuration changes'

# Each other supported manager is also selected when it is the available one.
for package_manager in pacman dnf; do
  manager_bin="$TEST_ROOT/$package_manager-bin"
  mkdir -p "$manager_bin"
  for command in bash dirname realpath git gpg ssh-keygen; do
    ln -s "$(command -v "$command")" "$manager_bin/$command"
  done
  printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$manager_bin/delta"
  printf '%s\n' '#!/usr/bin/env bash' 'exit 99' > "$manager_bin/$package_manager"
  chmod +x "$manager_bin/delta" "$manager_bin/$package_manager"

  manager_status=0
  PATH="$manager_bin" TERM=dumb \
    "$GIT_SETUP" help > "$TEST_ROOT/$package_manager-output" 2>&1 || manager_status=$?
  ((manager_status != 0)) || fail "$package_manager guidance did not stop git-setup"

  case $package_manager in
    pacman) require_output "$TEST_ROOT/$package_manager-output" 'Arch Linux (detected):' ;;
    dnf) require_output "$TEST_ROOT/$package_manager-output" 'Fedora (detected):' ;;
  esac
done

# Without a supported package manager, the failure names every required
# command and still gives the user all three supported installation paths.
NO_PACKAGE_MANAGER_BIN="$TEST_ROOT/no-package-manager-bin"
mkdir -p "$NO_PACKAGE_MANAGER_BIN"
for command in bash dirname realpath; do
  ln -s "$(command -v "$command")" "$NO_PACKAGE_MANAGER_BIN/$command"
done

no_package_manager_status=0
PATH="$NO_PACKAGE_MANAGER_BIN" TERM=dumb \
  "$GIT_SETUP" help > "$TEST_ROOT/no-package-manager-output" 2>&1 || no_package_manager_status=$?

((no_package_manager_status != 0)) || fail 'missing dependencies without a package manager did not stop git-setup'
require_output "$TEST_ROOT/no-package-manager-output" 'Missing commands: git gh gpg ssh-keygen delta'
require_output "$TEST_ROOT/no-package-manager-output" 'No supported package manager detected (pacman, apt, or dnf).'
require_output "$TEST_ROOT/no-package-manager-output" 'Install packages that provide: git gh gpg ssh-keygen delta.'
require_output "$TEST_ROOT/no-package-manager-output" 'sudo pacman -S --needed git github-cli gnupg openssh git-delta'
require_output "$TEST_ROOT/no-package-manager-output" 'sudo apt install git gh gnupg openssh-client git-delta'
require_output "$TEST_ROOT/no-package-manager-output" 'sudo dnf install git gh gnupg2 openssh-clients git-delta'

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
# shellcheck disable=SC2088 # The configured value intentionally contains a literal tilde.
[[ $(git config --file "$default_config" --get user.signingkey) == '~/.ssh/id_ed25519.pub' ]] || fail 'SSH signing key was not generated'
[[ $(git config --file "$default_config" --get gpg.format) == 'ssh' ]] || fail 'SSH signing format was not generated'
[[ $(git config --file "$default_config" --get core.pager) == 'delta' ]] || fail 'Delta pager was not generated'
require_output "$TEST_ROOT/default-config-output" 'Git Configuration Files'
require_output "$TEST_ROOT/default-config-output" 'Git + GitHub + GPG Configuration for Arch Linux'
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
require_output "$TEST_ROOT/verify-output" 'Git + GitHub + GPG Configuration for Arch Linux'
require_output "$TEST_ROOT/verify-output" 'Generated Git Configuration Files'
for file in "${generated_files[@]}"; do
  require_output "$TEST_ROOT/verify-output" "Found: ~/.config/git/$file"
done

# Clean must disclose the managed files and remain non-destructive until 'yes'.
printf 'no\n' | run_setup "$CUSTOM_HOME" clean > "$TEST_ROOT/clean-output"
require_output "$TEST_ROOT/clean-output" 'Git Configuration:'
# shellcheck disable=SC2088 # The expected user-facing path intentionally contains a literal tilde.
require_output "$TEST_ROOT/clean-output" '~/.config/git/config'
require_output "$TEST_ROOT/clean-output" 'gitconfig.local will be preserved'
require_output "$TEST_ROOT/clean-output" 'Cancelled'
require_file "$CUSTOM_HOME/.config/git/config"

# The integration test requires the identity generated by setup. Without it,
# it must not create a repository or prompt for a GitHub push.
UNCONFIGURED_HOME="$TEST_ROOT/unconfigured-home"
mkdir -p "$UNCONFIGURED_HOME"
run_setup "$UNCONFIGURED_HOME" test > "$TEST_ROOT/test-prerequisite-output" || true
require_output "$TEST_ROOT/test-prerequisite-output" 'Git identity is not configured'
require_output "$TEST_ROOT/test-prerequisite-output" 'Run option 2 (Run full setup) before the integration test'
if grep -Fq 'Push to GitHub?' "$TEST_ROOT/test-prerequisite-output"; then
  fail 'integration test offered a GitHub push without an identity'
fi

# Invoking without arguments remains the original interactive RaVN menu.
printf 'q\n' | run_setup "$CUSTOM_HOME" > "$TEST_ROOT/menu-output"
require_output "$TEST_ROOT/menu-output" 'Git + GitHub + GPG Configuration for Arch Linux'
require_output "$TEST_ROOT/menu-output" 'Choose an action'
require_output "$TEST_ROOT/menu-output" 'Verify current configuration'
require_output "$TEST_ROOT/menu-output" 'Help and usage'

# Help is available from both the direct command and the interactive menu.
run_setup "$CUSTOM_HOME" help > "$TEST_ROOT/help-output"
require_output "$TEST_ROOT/help-output" 'GITHUB TOKEN'
require_output "$TEST_ROOT/help-output" 'CONFIGURATION FILES'
printf 'h\n\nq\n' | run_setup "$CUSTOM_HOME" > "$TEST_ROOT/menu-help-output"
require_output "$TEST_ROOT/menu-help-output" 'RECOMMENDED FLOW'
[[ $(grep -Fc 'Choose an action' "$TEST_ROOT/menu-help-output") -eq 2 ]] || fail 'menu did not return after help'

# A failed verification in the interactive menu must still return to the menu
# after the user acknowledges the result.
printf '1\n\nq\n' | run_setup "$CUSTOM_HOME" > "$TEST_ROOT/menu-return-output"
[[ $(grep -Fc 'Choose an action' "$TEST_ROOT/menu-return-output") -eq 2 ]] || fail 'menu did not return after verification'

printf 'PASS: git-setup managed configuration and interactive workflow\n'
