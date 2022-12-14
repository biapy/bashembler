#!/usr/bin/env bash
# @file src/internals/sourced-file-path.bash
# @author Pierre-Yves Landuré < contact at biapy dot fr >
# @brief Compute sourced file path from a bash source (or dot) command.
# @description
#   `sourced-file-path` is a sub-function of `assemble-sources` that compute
#   a source command sourced file path.
# @see assemble-sources

# shellcheck source-path=SCRIPTDIR
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/cecho.bash"
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/realpath.bash"
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/process-options.bash"

# @description Get sourced file from source (or dot) command.
#   When `--origin` option is not provided, the source content is returned as
#   is, without any modification.
#   When `--origin` option is provided, the function try to locate the sourced
#   file and return an error on failure.
#   If the file is located, it output the sourced file absolute path.
#
# @example
#     source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/internals/sourced-file-path.bash"
#     sourced_file="$(
#         sourced-file-path 'source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/cecho.bash"'
#       )"
#
# @option -q | --quiet Disable error messages when present.
# @option -v | --verbose Trigger verbose mode when present.
# @option --origin The file in which the source command is found.
#
# @arg $1 string A Bash source or . (dot) include command.
#
# @stdout Source command argument if `--origin` is not provided.
# @stdout Sourced file absolute path if `--origin` is provided and file is found.
#
# @stderr Error if invalid option is given.
# @stderr Error if argument is missing or too many arguments given.
# @stderr Error if source command can't be parsed.
# @stderr Error if sourced file does not exists.
#
# @exitcode 0 on success.
# @exitcode 1 if invalid option is given.
# @exitcode 1 if argument is missing or too many arguments given.
# @exitcode 1 if source command can't be parsed.
# @exitcode 1 if sourced file does not exists.
function sourced-file-path {
  # Declare variables as local.
  local allowed_options
  local arguments
  local origin=''
  local quiet=0
  local verbose=0
  local source_command
  local file
  local file_realpath
  local cleaned_file
  local input_folder

  # Detect if quiet mode is enabled, to allow for output silencing.
  in-list "(-q|--quiet)" ${@+"$@"} && quiet=1
  in-list "(-v|--verbose)" ${@+"$@"} && verbose=1

  # Conditionnal output redirection.
  local fd_target
  local error_fd
  # Detect first available file descriptor.
  error_fd=9
  while ((++error_fd < 200)); do
    # shellcheck disable=SC2188 # Ignore a file descriptor availability test.
    ! <&"${error_fd}" && break
  done 2> '/dev/null'
  # Configure file descriptor redirection to stderr or /dev/null
  if ((error_fd < 200)); then
    fd_target='&2'
    ((quiet)) && fd_target='/dev/null'
    eval "exec ${error_fd}>${fd_target}"
  else
    error_fd=2
  fi

  local verbose_fd
  # Detect first available file descriptor.
  verbose_fd=9
  while ((++verbose_fd < 200)); do
    # shellcheck disable=SC2188 # Ignore a file descriptor availability test.
    ! <&"${verbose_fd}" && break
  done 2> '/dev/null'
  # Configure file descriptor redirection to stderr or /dev/null
  if ((verbose_fd < 200)); then
    fd_target='/dev/null'
    ((verbose)) && fd_target='&2'
    eval "exec ${verbose_fd}>${fd_target}"
    cecho "DEBUG" "Debug: Verbose mode enabled in ${FUNCNAME[0]}." >&"${verbose_fd-2}"
  else
    verbose_fd=2
  fi

  # Function closing error redirection file descriptors.
  # to be called before exiting this function.
  function close-fds() {
    [[ "${error_fd-2}" -ne 2 ]] && eval "exec ${error_fd-}>&-"
    [[ "${verbose_fd-2}" -ne 2 ]] && eval "exec ${verbose_fd-}>&-"
  }

  # Call the process-options function:
  declare -a arguments
  declare -a allowed_options
  allowed_options=('verbose' 'quiet' 'origin&')

  ### Process function options.
  ### Process function options.
  if ! process-options "${allowed_options[*]}" ${@+"$@"} 2>&"${error_fd-2}"; then
    close-fds
    return 1
  fi

  # Accept one and only one argument.
  if [[ ${#arguments[@]} -ne 1 ]]; then
    cecho "ERROR" "Error: ${FUNCNAME[0]} requires one and only one argument." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  source_command="${arguments[0]}"

  cecho 'DEBUG' "Debug: Extracting file path from source command '${source_command-}'." >&"${verbose_fd-2}"
  # shellcheck disable=SC1003
  file="$(echo "${source_command-}" \
    | sed -Ee 's#^[[:blank:]]*(source|\.)[[:blank:]]+("((\\"|[^"])*)"|'\''((\\'\''|[^'\''])*)'\''|((\\[ \t]|[^ \t])*))?[[:blank:]]*(;.*|\#.*)?$#\3\5\7#' \
        || true)"
  cecho 'DEBUG' "Debug: Detected file path '${file-}'." >&"${verbose_fd-2}"

  if [[ "${file-}" = "${source_command-}" ]]; then
    cecho "ERROR" "Error: unable to extract file from command '${source_command-}'." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  if [[ -z "${origin-}" ]]; then
    cecho 'DEBUG' "Debug: Sourced file origin was not provided." >&"${verbose_fd-2}"
    # Origin is not specified, return file path as is.
    echo "${file-}"
    return 0
  fi

  input_folder="$( dirname "$( realpath "${origin-}" || true)")"

  if [[ "${file-}" =~ ^/ ]]; then
    # Sourced file with absolute path.
    cecho 'DEBUG' "Debug: Sourced file path is absolute: '${file-}'." >&"${verbose_fd-2}"

    file_realpath="$(realpath "${file-}")"
  elif [[ "${file-}" =~ ^\$\{BASH_SOURCE\[0\]%/\*\} ]]; then
    # Sourced file with variable parts.
    cecho 'DEBUG' "Debug: Sourced file starts with variable parts." >&"${verbose_fd-2}"
    cecho 'DEBUG' "Debug: Removing variable parts from '${file-}'" >&"${verbose_fd-2}"
    # shellcheck disable=SC2016
    cleaned_file="$(echo "${file-}" \
      | sed --expression='s#^\${BASH_SOURCE\[0\]%/\*}/##')"
    cecho 'DEBUG' "Debug: Removal result is '${cleaned_file-}'" >&"${verbose_fd-2}"

    cecho 'DEBUG' "Debug: Finding realpath for '${input_folder-}/${cleaned_file-}'" >&"${verbose_fd-2}"
    file_realpath="$(realpath "${input_folder-}/${cleaned_file-}")"
  else
    # Sourced file with relative path.
    cecho 'DEBUG' "Debug: Sourced file path is relative: '${file-}'." >&"${verbose_fd-2}"
    cecho 'DEBUG' "Debug: Finding realpath for '${input_folder-}/${file-}'" >&"${verbose_fd-2}"
    file_realpath="$(realpath "${input_folder-}/${file-}")"
  fi

  # Return failure if file does not exists.
  if [[ -z "${file_realpath-}" ]]; then
    cecho 'ERROR' "Error: sourced file '${file-}' does not exists." >&"${error_fd-2}"
    close-fds
    return 1
  elif [[ ! -e "${file_realpath-}" ]]; then
    cecho 'ERROR' "Error: sourced file '${file-}' (real path '${file_realpath-}') does not exists." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  # Output file realpath and return success if file exists.
  cecho 'DEBUG' "Debug: sourced file realpath is '${file_realpath-}'" >&"${verbose_fd-2}"
  echo "${file_realpath-}"
  close-fds
  return 0
}
