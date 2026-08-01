#!/usr/bin/env bash

# Resolve a public command name and execute its autonomous command module.
dispatch_command() {
  local command="${1:-}"
  local script=""

  case "$command" in
    verify | v | --verify | -v)
      script="$PROJECT_DIR/scripts/verify"
      ;;
    config | f | --config | -f)
      script="$PROJECT_DIR/scripts/config"
      ;;
    setup | s | --setup | -s)
      script="$PROJECT_DIR/scripts/setup"
      ;;
    test | t | --test | -t)
      script="$PROJECT_DIR/scripts/test"
      ;;
    clean | c | --clean | -c)
      script="$PROJECT_DIR/scripts/clean"
      ;;
    help | h | --help | -h)
      script="$PROJECT_DIR/scripts/help"
      ;;
    *)
      print_error "Unknown command: $command"
      return 2
      ;;
  esac

  if [[ ! -x $script ]]; then
    print_error "Command module is not executable: $script"
    return 1
  fi

  shift
  "$script" "$@"
}
