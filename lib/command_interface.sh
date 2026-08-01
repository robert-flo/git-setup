#!/usr/bin/env bash

# Run a command module's no-argument operation or its self-describing help.
run_command_entrypoint() {
  local command_name="$1"
  local help_function="$2"
  local operation_function="$3"
  shift 3

  if (($# == 0)); then
    "$operation_function"
    return $?
  fi

  if (($# == 1)) && [[ $1 == "-h" || $1 == "--help" ]]; then
    "$help_function"
    return 0
  fi

  print_error "Unknown option for $command_name: $1"
  "$help_function"
  return 2
}
