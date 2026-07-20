#!/usr/bin/env bash

set -Eeuo pipefail

TEST_ROOT="$(mktemp -d "${TMPDIR:-/tmp}/git-setup-docker-make-test.XXXXXX")"
TEST_BIN="$TEST_ROOT/bin"
DOCKER_LOG="$TEST_ROOT/docker.log"

trap 'rm -rf "$TEST_ROOT"' EXIT

fail() {
  printf 'FAIL: %s\n' "$1" >&2
  exit 1
}

mkdir -p "$TEST_BIN"
# shellcheck disable=SC2016 # The generated Docker stub expands this at runtime.
printf '%s\n' \
  '#!/usr/bin/env bash' \
  'printf "%s\n" "$*" >> "$DOCKER_LOG"' > "$TEST_BIN/docker"
chmod +x "$TEST_BIN/docker"

PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-build DOCKER_ENV=ubuntu > "$TEST_ROOT/build-output"

grep -Fqx 'build --file docker/ubuntu.Dockerfile --tag git-setup:ubuntu-local .' "$DOCKER_LOG" || \
  fail 'Ubuntu build did not select its Dockerfile and image'

: > "$DOCKER_LOG"
PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-build > "$TEST_ROOT/arch-build-output"

grep -Fqx 'build --file Dockerfile --tag git-setup:local .' "$DOCKER_LOG" || \
  fail 'default build did not preserve the Arch Docker image'

PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-build DOCKER_ENV=fedora > "$TEST_ROOT/fedora-build-output"

grep -Fqx 'build --file docker/fedora.Dockerfile --tag git-setup:fedora-local .' "$DOCKER_LOG" || \
  fail 'Fedora build did not select its Dockerfile and image'

: > "$DOCKER_LOG"
PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-run DOCKER_ENV=fedora > "$TEST_ROOT/fedora-run-output"

grep -Fqx 'run --rm -it git-setup:fedora-local' "$DOCKER_LOG" || \
  fail 'Fedora run was not interactive and ephemeral'

: > "$DOCKER_LOG"
PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-clean-all > "$TEST_ROOT/clean-all-output"

for image in git-setup:local git-setup:ubuntu-local git-setup:fedora-local; do
  grep -Fqx "image rm $image" "$DOCKER_LOG" || fail "docker-clean-all did not remove $image"
done

while IFS= read -r docker_command; do
  case $docker_command in
    'image inspect git-setup:local' | 'image rm git-setup:local' | \
    'image inspect git-setup:ubuntu-local' | 'image rm git-setup:ubuntu-local' | \
    'image inspect git-setup:fedora-local' | 'image rm git-setup:fedora-local') ;;
    *) fail "docker-clean-all touched an unexpected resource: $docker_command" ;;
  esac
done < "$DOCKER_LOG"

invalid_environment_status=0
: > "$DOCKER_LOG"
PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-build DOCKER_ENV=debian > "$TEST_ROOT/invalid-environment-output" 2>&1 || \
  invalid_environment_status=$?

((invalid_environment_status != 0)) || fail 'an unsupported Docker environment did not fail'
grep -Fq 'Unsupported DOCKER_ENV: debian' "$TEST_ROOT/invalid-environment-output" || \
  fail 'unsupported Docker environment did not explain the valid choices'
[[ ! -s $DOCKER_LOG ]] || fail 'unsupported Docker environment invoked Docker'

unmanaged_cleanup_status=0
: > "$DOCKER_LOG"
PATH="$TEST_BIN:$PATH" DOCKER_LOG="$DOCKER_LOG" \
  make --no-print-directory docker-clean DOCKER_IMAGE=unrelated:local > "$TEST_ROOT/unmanaged-cleanup-output" 2>&1 || \
  unmanaged_cleanup_status=$?

((unmanaged_cleanup_status != 0)) || fail 'cleanup accepted an unmanaged Docker image'
grep -Fq 'Refusing to remove unmanaged Docker image: unrelated:local' "$TEST_ROOT/unmanaged-cleanup-output" || \
  fail 'cleanup did not explain why the image was rejected'
[[ ! -s $DOCKER_LOG ]] || fail 'cleanup invoked Docker for an unmanaged image'

printf 'PASS: Make selects and cleans Docker environments\n'
