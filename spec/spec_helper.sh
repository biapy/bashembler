#!/bin/bash
# shellcheck shell=bash

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
# set -eu

# This callback function will be invoked only once before loading specfiles.
function spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.28.1"

  # shellcheck disable=SC2154
  if [[ "${SHELL_TYPE}" != "bash" ]]; then
    abort "Only bash is supported."
  fi
}

# This callback function will be invoked after a specfile has been loaded.
function spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
function spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'
}

# Setup sourcing tests files for bashembler and include-sources functions.
function setup-sourcing-tests() {
  sourced_file="$(mktemp || true)"

  # On MacOS /var is a symbolic link to /private/var.
  if [[ -e "/private${sourced_file}" ]]; then
      prefix="/private"
      sourced_file="${prefix}${sourced_file}"
  fi

  output_file="${prefix}$(mktemp -u || true)"
  existing_output_file="${prefix}$(mktemp)"

  readonly_output_path="${prefix}$(mktemp -d)"
  chmod ugo-w "${readonly_output_path}"

  [[ -e "${sourced_file}" ]] && cat - > "${sourced_file}" << EOF
#!/bin/bash
# Sourced file contents
echo "The sourced file contents."
EOF

  origin_file="${prefix}$(mktemp || true)"
  [[ -e "${origin_file}" ]] && cat - > "${origin_file}" << EOF
#!/bin/bash
# Origin file contents
echo "The origin file contents."
source "${sourced_file}"
EOF

  circular_sourcing_file="${prefix}$(mktemp || true)"
  [[ -e "${circular_sourcing_file}" ]] \
      && cat - > "${circular_sourcing_file}" << EOF
#!/bin/bash
source "${circular_sourcing_file##*/}"
echo "This file source itself infinitely."
EOF

  infinite_sourcing_file="${prefix}$(mktemp || true)"
  [[ -e "${infinite_sourcing_file}" ]] \
      && cat - > "${infinite_sourcing_file}" << EOF
#!/bin/bash
echo "The infinite sourcing file contents."
source "${circular_sourcing_file}"
EOF

  source_missing_file="${prefix}$(mktemp || true)"
  missing_target_file="missing-random-file-${source_missing_file##*/}"
  [[ -e "${source_missing_file}" ]] \
      && cat - > "${source_missing_file}" << EOF
#!/bin/bash
source "${missing_target_file}"
echo "This file source a missing file."
EOF

  broken_sourcing_file="${prefix}$(mktemp || true)"
  [[ -e "${broken_sourcing_file}" ]] && cat - > "${broken_sourcing_file}" << EOF
#!/bin/bash
echo "The broken script sourcing file contents."
source "${source_missing_file}"
EOF

  return 0
}

# Cleanup sourcing tests files for bashembler and include-sources functions.
function cleanup-sourcing-tests() {
  [[ -e "${sourced_file}" ]] && rm "${sourced_file}"
  [[ -e "${output_file}" ]] && rm "${output_file}"
  [[ -e "${existing_output_file}" ]] && rm "${existing_output_file}"
  [[ -e "${readonly_output_path}" ]] && rm -rf "${readonly_output_path}"
  [[ -e "${origin_file}" ]] && rm "${origin_file}"
  [[ -e "${circular_sourcing_file}" ]] && rm "${circular_sourcing_file}"
  [[ -e "${infinite_sourcing_file}" ]] && rm "${infinite_sourcing_file}"
  [[ -e "${source_missing_file}" ]] && rm "${source_missing_file}"
  [[ -e "${broken_sourcing_file}" ]] && rm "${broken_sourcing_file}"

  return 0
}
