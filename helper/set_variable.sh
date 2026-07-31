#!/usr/bin/env bash

# Shared runtime paths for the root dispatcher and future command modules.
helper_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
readonly GIT_SETUP_ROOT="${GIT_SETUP_ROOT:-$(cd "$helper_dir/.." && pwd)}"
readonly GIT_SETUP_LEGACY_ENTRYPOINT="$GIT_SETUP_ROOT/bin/git-setup"
TEMPLATE_DIR="${TEMPLATE_DIR:-$GIT_SETUP_ROOT/templates/git}"
GIT_CONFIG_DIR="${GIT_CONFIG_DIR:-$HOME/.config/git}"
GIT_CONFIG_FILE="${GIT_CONFIG_FILE:-$GIT_CONFIG_DIR/config}"
WORKFLOW_COMMAND_DIR="${WORKFLOW_COMMAND_DIR:-$HOME/.local/bin}"
USER_NAME="${USER_NAME:-${NAME:-Roberto Flores}}"
USER_EMAIL="${USER_EMAIL:-${EMAIL:-25asab015@ujmd.edu.sv}}"

export GIT_SETUP_ROOT
export GIT_SETUP_LEGACY_ENTRYPOINT
export TEMPLATE_DIR
export GIT_CONFIG_DIR
export GIT_CONFIG_FILE
export WORKFLOW_COMMAND_DIR
export USER_NAME
export USER_EMAIL
