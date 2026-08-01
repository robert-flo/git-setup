#!/usr/bin/env bash

# One declarative record per public command, shared by dispatch, menu, help,
# and future completion. Fields: canonical|aliases|label|description|icon|menu.
# shellcheck disable=SC2034 # Public catalog consumed by sourced capabilities.
readonly -a GIT_SETUP_COMMAND_CATALOG=(
  "config|f --config -f|Config|Create or refresh the managed Git configuration files.|${RAVN_ICON[ui_gear]}|0"
  "verify|v --verify -v|Verify current configuration|Review Git, SSH, GPG, GitHub, and generated configuration files.|${RAVN_ICON[ui_check]}|1"
  "setup|s --setup -s|Run full setup|Configure GitHub, SSH, GPG, and commit signing.|${RAVN_ICON[ui_gear]}|1"
  "test|t --test -t|Run integration test|Create a test repository and verify a signed commit.|${RAVN_ICON[ui_test]}|1"
  "clean|c --clean -c|Clean local config (fresh start)|Remove configuration created by git-setup after confirmation.|${RAVN_ICON[ui_trash]}|1"
  "help|h --help -h|Help and usage|Show this guide.|󰋖|1"
)

command_catalog_get() {
  local lookup="$1"
  local requested_field="$2"
  local record=""
  local canonical=""
  local aliases=""
  local label=""
  local description=""
  local icon=""
  local menu=""
  local value=""

  for record in "${GIT_SETUP_COMMAND_CATALOG[@]}"; do
    IFS='|' read -r canonical aliases label description icon menu <<< "$record"
    if [[ $canonical == "$lookup" || " $aliases " == *" $lookup "* ]]; then
      case "$requested_field" in
        canonical) value="$canonical" ;;
        aliases) value="$aliases" ;;
        label) value="$label" ;;
        description) value="$description" ;;
        icon) value="$icon" ;;
        menu) value="$menu" ;;
        module) value="$canonical" ;;
        *)
          GIT_SETUP_COMMAND_CATALOG_ERROR="Unknown metadata field: $requested_field"
          return 1
          ;;
      esac
      # shellcheck disable=SC2034 # Read by the caller in the same shell.
      GIT_SETUP_COMMAND_CATALOG_VALUE="$value"
      return 0
    fi
  done

  GIT_SETUP_COMMAND_CATALOG_ERROR="Unknown command: $lookup"
  return 1
}

command_catalog_list() {
  local include_menu="$1"
  local record=""
  local canonical=""
  local aliases=""
  local label=""
  local description=""
  local icon=""
  local menu=""

  for record in "${GIT_SETUP_COMMAND_CATALOG[@]}"; do
    IFS='|' read -r canonical aliases label description icon menu <<< "$record"
    if [[ $include_menu == all || $menu == 1 ]]; then
      printf '%s\n' "$canonical"
    fi
  done
}
