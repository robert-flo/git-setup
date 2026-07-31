#!/usr/bin/env bash

set -Eeuo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/git-setup-workflow-test.XXXXXX")"
REPOSITORY="$TEST_ROOT/repository"
TEST_BIN="$TEST_ROOT/bin"

trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

require_aligned_quick_actions() {
  sed -E 's/\x1B\[[0-9;]*m//g' "$1" | awk '
  /^  • / {
    git_column = index($0, "git ")
    make_column = index($0, "make ")
    if (!seen++) { expected_git = git_column; expected_make = make_column }
    if (git_column != expected_git || make_column != expected_make) exit 1
  }
  END { if (!seen) exit 1 }' || fail "Quick Actions are not aligned: $2"
}

mkdir -p "$REPOSITORY" "$TEST_BIN"
printf '%s\n' '#!/usr/bin/env bash' 'exit 0' > "$TEST_BIN/fzf"
chmod +x "$TEST_BIN/fzf"
cp "$ROOT_DIR/Makefile" "$REPOSITORY/Makefile"
cp -R "$ROOT_DIR/make" "$REPOSITORY/make"
git -C "$REPOSITORY" init -q
git -C "$REPOSITORY" config user.name 'Workflow Test'
git -C "$REPOSITORY" config user.email workflow@example.test
printf 'tracked\n' > "$REPOSITORY/tracked.txt"
git -C "$REPOSITORY" add tracked.txt
git -C "$REPOSITORY" commit -qm 'initial workflow fixture'
printf 'untracked\n' > "$REPOSITORY/untracked.txt"

# The current long Make target is the independent output-parity reference. The
# Quick Actions are intentionally excluded because portable commands teach all
# three workflow surfaces.
(
  cd "$REPOSITORY"
  make --no-print-directory git-status | sed '/✓ done/,$d; s/  [0-9][0-9]* [a-z]* ago/  <relative-time>/g' > "$TEST_ROOT/make-status"
  ./make/s | sed '/✓ done/,$d; s/  [0-9][0-9]* [a-z]* ago/  <relative-time>/g' > "$TEST_ROOT/direct-status"
)
cmp "$TEST_ROOT/make-status" "$TEST_ROOT/direct-status" || fail 'direct status changed the Make status body'

# shellcheck disable=SC2016 # Git must store these expansions for alias runtime.
git -C "$REPOSITORY" config alias.s "$(git config --file "$ROOT_DIR/templates/git/gitconfig_aliases" --get alias.s)"
mkdir "$REPOSITORY/nested"
(
  cd "$REPOSITORY/nested"
  PATH="$REPOSITORY/make:$PATH" git s > "$TEST_ROOT/git-status"
)
sed -E 's/\x1B\[[0-9;]*m//g' "$TEST_ROOT/git-status" > "$TEST_ROOT/git-status-plain"
grep -Fq "path:      $REPOSITORY/nested" "$TEST_ROOT/git-status-plain" || \
  fail 'git s did not preserve the subdirectory invocation context'
grep -Fq 'stage and commit:' "$TEST_ROOT/git-status" || fail 'status omitted Quick Actions'
grep -Fq 'git ac' "$TEST_ROOT/git-status" || fail 'status did not teach the Git workflow surface'
grep -Fq 'make ac' "$TEST_ROOT/git-status" || fail 'status did not teach the Make workflow surface'
require_aligned_quick_actions "$TEST_ROOT/git-status" 'git s'
(
  cd "$REPOSITORY"
  make --no-print-directory git-status
) > "$TEST_ROOT/long-make-status"
require_aligned_quick_actions "$TEST_ROOT/long-make-status" 'make git-status'

# Every visible adapter is exercised at its public direct and Make seams. The
# mutating operations run in preview mode so the fixture remains reusable.
for command in a c ac p l st s d lg af fuck bye clean df; do
  (
    cd "$REPOSITORY"
    PATH="$TEST_BIN:$PATH" DRY_RUN=1 "./make/$command" > "$TEST_ROOT/direct-$command"
    PATH="$TEST_BIN:$PATH" DRY_RUN=1 make --no-print-directory "$command" > "$TEST_ROOT/make-$command"
  )
  [[ -s $TEST_ROOT/direct-$command ]] || fail "direct $command produced no public output"
  [[ -s $TEST_ROOT/make-$command ]] || fail "make $command produced no public output"
done
for command in cm fc fm; do
  (
    cd "$REPOSITORY"
    PATH="$TEST_BIN:$PATH" DRY_RUN=1 "./make/$command" 'workflow query' > "$TEST_ROOT/direct-$command"
    PATH="$TEST_BIN:$PATH" DRY_RUN=1 make --no-print-directory "$command" 'workflow query' > "$TEST_ROOT/make-$command"
  )
  [[ -s $TEST_ROOT/direct-$command ]] || fail "direct $command did not accept its positional argument"
  [[ -s $TEST_ROOT/make-$command ]] || fail "make $command did not accept its positional argument"
done

# The generated Git shell aliases preserve output parity with their direct
# surface. The native `git clean` exception is represented by `git bye`.
for command in a c cm ac p l st s d lg af fuck bye df fc fm; do
  git -C "$REPOSITORY" config "alias.$command" "$(git config --file "$ROOT_DIR/templates/git/gitconfig_aliases" --get "alias.$command")"
  (
    cd "$REPOSITORY/nested"
    if [[ $command == cm || $command == fc || $command == fm || $command == fuck ]]; then
      PATH="$TEST_BIN:$REPOSITORY/make:$PATH" DRY_RUN=1 "$REPOSITORY/make/$command" 'workflow query' > "$TEST_ROOT/direct-git-$command"
      PATH="$TEST_BIN:$REPOSITORY/make:$PATH" DRY_RUN=1 git "$command" 'workflow query' > "$TEST_ROOT/git-$command"
    else
      PATH="$TEST_BIN:$REPOSITORY/make:$PATH" DRY_RUN=1 "$REPOSITORY/make/$command" > "$TEST_ROOT/direct-git-$command"
      PATH="$TEST_BIN:$REPOSITORY/make:$PATH" DRY_RUN=1 git "$command" > "$TEST_ROOT/git-$command"
    fi
  )
  sed -E \
    -e 's/  [0-9][0-9]* [a-z]* ago/  <relative-time>/g' \
    -e 's/config: update [0-9-]+ [0-9:]+/config: update <timestamp>/g' \
    "$TEST_ROOT/direct-git-$command" > "$TEST_ROOT/direct-git-$command-normalized"
  sed -E \
    -e 's/  [0-9][0-9]* [a-z]* ago/  <relative-time>/g' \
    -e 's/config: update [0-9-]+ [0-9:]+/config: update <timestamp>/g' \
    "$TEST_ROOT/git-$command" > "$TEST_ROOT/git-$command-normalized"
  cmp "$TEST_ROOT/direct-git-$command-normalized" "$TEST_ROOT/git-$command-normalized" || \
    fail "git $command changed the direct workflow output"
done

printf 'PASS: managed workflow status preserves its public surfaces\n'
