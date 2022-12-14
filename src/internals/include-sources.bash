#!/usr/bin/env bash
# @file src/internal/include-sources.bash
# @author Pierre-Yves Landuré < contact at biapy dot fr >
# @brief `bashembler` logic, recursivly including sourced files in main script.

# shellcheck source-path=SCRIPTDIR
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/cecho.bash"
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/process-options.bash"
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/realpath.bash"
source "${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/repeat-string.bash"
source "${BASH_SOURCE[0]%/*}/sourced-file-path.bash"

# @description
#     include-sources read line by line a bash (or sh script) and look for
#     `source` (or dot (i.e. `.`)) commands. When a `source` command is
#     encountered, `include-sources` try to resolve the sourced file path, and
#     recursively process the sourced files. Each read line is outputed as is
#     to `/dev/stdout`, except for the source commands which are replaced by
#     the sourced files.
#
# @see https://stackoverflow.com/questions/37531927/replacing-source-file-with-its-content-and-expanding-variables-in-bash
#
# @example
#   source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/internals/include-sources.bash"
#   $contents="$( include-sources --origin="src/my-script.bash" "src/my-script.bash" )"
#
# @option -q | --quiet Disable error messages when present.
# @option -v | --verbose Trigger verbose mode when present.
# @option --discard-comments Remove comment lines (eg, starting by '#') from assembled file.
# @option --level=<level> The distance from origin shell script (0 for origin).
# @option --origin=<origin-file-path> The origin shell script file path (i.e, first processed file, before recursion).
# @option --output=<output-file-path> The output shell script file path.
#
# @arg $1 string A `bash` (or `sh`) script file.
#
# @stdout The one-file version of the $1 script, with sourced files included, if `--output` is not used.
# @stderr Error if argument is missing, or more than one argument provided.
# @stderr Error if invalid option provided.
# @stderr Error if include-sources is unable to find a sourced file.
#
# @exitcode 0 If `bash`` script assembly is successful.
# @exitcode 1 If include-sources failed to assemble the script.
# @exitcode 1 If argument is missing, or more than one argument provided.
# @exitcode 1 If include-sources is unable to find a sourced file.
#
# @see [cecho](https://github.com/biapy/biapy-bashlings/blob/main/doc/cecho.md)
# @see [realpath](https://github.com/biapy/biapy-bashlings/blob/main/doc/realpath.md)
# @see [repeat-string](https://github.com/biapy/biapy-bashlings/blob/main/doc/repeat-string.md)
# @see [process-options](https://github.com/biapy/biapy-bashlings/blob/main/doc/process-options.md)
# @see [sourced-file-path](./sourced-file-path.md#sourced-file-path)
function include-sources() {
  local allowed_options
  # Declare option variables as local.
  local arguments
  local quiet=0
  local verbose=0
  local discard_comments=0
  local origin=''
  local input
  local output='/dev/stdout'
  local options
  local include_options

  local line
  local line_count
  local source_command
  local sourced_file
  local level=0
  local indent=''
  local indent_string=' | '

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

  cecho "DEBUG" "Debug: entering function ${FUNCNAME[0]}" ${@+"$@"} "." >&"${verbose_fd-2}"

  # Function closing error redirection file descriptors.
  # to be called before exiting this function.
  function close-fds() {
    [[ "${error_fd-2}" -ne 2 ]] && eval "exec ${error_fd-}>&-"
    [[ "${verbose_fd-2}" -ne 2 ]] && eval "exec ${verbose_fd-}>&-"
  }

  declare -a arguments
  arguments=()
  declare -a allowed_options
  allowed_options=('verbose' 'quiet' 'discard-comments' 'level&' 'origin&' 'output&')
  ### Process function options.
  cecho "DEBUG" "Debug: processing options." >&"${verbose_fd-2}"
  if ! process-options "${allowed_options[*]}" ${@+"$@"} 2>&"${error_fd-2}"; then
    cecho "DEBUG" "Debug: options processing failed." >&"${verbose_fd-2}"
    close-fds
    return 1
  fi

  declare -a options
  options=()
  [[ "${quiet-0}" -ne 0 ]] && options+=('--quiet')
  [[ "${verbose-0}" -ne 0 ]] && options+=('--verbose')

  declare -a include_options
  include_options=()
  [[ "${discard_comments-0}" -ne 0 ]] && include_options+=('--discard-comments')

  # Ensure level is an integer
  if [[ -z "${level}" || ! "${level}" =~ ^[0-9]+$ ]]; then
    cecho "ERROR" "Error: --level value is not an integer." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  # Accept one and only one argument.
  cecho "DEBUG" "Debug: checking provided arguments count." >&"${verbose_fd-2}"
  if [[ ${#arguments[@]} -ne 1 ]]; then
    cecho "ERROR" "Error: ${FUNCNAME[0]} requires one and only one argument." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  # Fetch input file path from arguments.
  # Using stdin as output is impossible, since it prevent the detection of
  # sourced files path.
  input="${arguments[0]-}"

  # Set output to stdout if dash given.
  [[ "${output--}" = "-" ]] && output="/dev/stdout"

  # Test if input file exists.
  cecho "DEBUG" "Debug: check if input file '${input-}' exists." >&"${verbose_fd-2}"
  if [[ ! -e "${input}" ]]; then
    cecho "ERROR" "Error: file '${input-}' does not exists." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  # Test if output file can be created in given path.
  cecho "DEBUG" "Debug: check if output file can be created in given path." >&"${verbose_fd-2}"
  if [[ "${output-}" != "/dev/stdout" && ! -d "$(dirname "${output-}")" ]]; then
    cecho "ERROR" "Error: file '${output-}' directory does not exists." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  # Generate sourced file message indent.
  indent="$(repeat-string "${level}" "${indent_string}")"

  # If the file is not a sourced file (ie. is the root shellscript),
  if [[ -z "${origin-}" ]]; then
    # Make sure level is 0 when the file is the root shellscript.
    if ((level > 0)); then
      cecho "ERROR" "Error: --level option requires --origin to be specified." >&"${error_fd-2}"
      close-fds
      return 1
    fi

    cecho 'SUCCESS' "Assembling ${input-}" >&"${error_fd-2}"

    # Initialize output file
    cecho "DEBUG" "Debug: initialization of output file." >&"${verbose_fd-2}"
    [[ "${output-}" != "/dev/stdout" ]] && echo -n "" > "${output-}"

    # Declare sourced_files list for this function and its recursions.
    local sourced_files=()
  elif ((level > 0)); then
    # Level is specified and origin is not empty,
    # the input file is a sourced file.
    cecho 'SUCCESS' "${indent}${input##*/}" >&"${error_fd-2}"
  fi

  cecho "DEBUG" "Debug: looping over input file '${input-}' lines." >&"${verbose_fd-2}"
  # Read input file line by line.
  # || [[ -n "${line}" ]] allow to get last line if no new line is added.
  line=''
  line_count=0
  # shellcheck disable=SC2094
  while IFS='' read -r 'line' || [[ -n "${line-}" ]]; do
    ((++line_count))

    cecho "DEBUG" "Debug: processing line n°${line_count-} of '${input-}'." >&"${verbose_fd-2}"
    cecho "DEBUG" "Debug: line n°${line_count-} is '${line-}'." >&"${verbose_fd-2}"

    # If the file is a sourced file, remove shebang.
    if [[ -n "${origin}" && "${line_count}" -eq 1 && "${line}" =~ ^\#\! ]]; then
      cecho 'DEBUG' "Debug: discarding shebang at line ${line_count} of file '${input}'." >&"${verbose_fd-2}"
      # Skip shebang.
      continue
    fi

    # Discard comments except initial shebang.
    if [[ "${discard_comments}" -ne 0 && "${line}" =~ ^[[:blank:]]*\# &&
         ! (-z "${origin}" && "${line_count}" -eq 1)   ]]; then
      cecho 'DEBUG' "Debug: discarding comment at line ${line_count} of file '${input}'." >&"${verbose_fd-2}"
      # Skip comment.
      continue
    fi

    # Detect if line contains a source command.
    source_command="$(echo "${line-}" \
      | grep --extended-regexp '^[[:blank:]]*(source|\.)[[:blank:]]' || true)"

    # If line is not a source command,
    if [[ -z "${source_command-}" ]]; then
      # Write line as is in output.
      echo -E "${line-}" >> "${output-}"
      # Continue with next line.
      continue
    fi

    # If line contains a source command, recurse in source.
    cecho 'DEBUG' "Debug: detected source command '${source_command}' at line ${line_count} of file '${input}'." >&"${verbose_fd-2}"
    # Detect sourced filename.
    sourced_file=''
    # Detect if ogirin is set.
    if [[ -n "${origin}" ]]; then
      # If origin is set, try to get sourced file path relative to origin.
      cecho 'DEBUG' "Debug: trying to get source file relative to origin '${origin}'." >&"${verbose_fd-2}"
      if ! sourced_file="$(
        sourced-file-path ${options[@]+"${options[@]}"} \
          --origin="${origin-}" \
          "${source_command-}" 2>&"${verbose_fd-2}"
      )"; then
        # Ensure sourced_file is empty on failure.
        # Another detection without using origin will be attempted.
        sourced_file=''
      fi
    fi

    # If sourced file path is still not found,
    if [[ -z "${sourced_file}" ]]; then
      # try to get sourced file path relative to input file.
      cecho 'DEBUG' "Debug: trying to get source file relative to input '${input}'." >&"${verbose_fd-2}"
      if ! sourced_file="$(
        sourced-file-path ${options[@]+"${options[@]}"} \
          --origin="${input-}" \
          "${source_command-}" 2>&"${verbose_fd-2}"
      )"; then
        cecho "ERROR" "Error: can not resolve command '${source_command-}' in file '${input}'." >&"${error_fd-2}"
        close-fds
        return 1
      fi
    fi

    # If the sourced-file path is empty, skip to next line.
    if [[ -z "${sourced_file-}" ]]; then
      continue
    fi

    # If the sourced-file-path is call is successfull.
    # Detect the root origin of the assemblage.
    local source_origin="${input-}"
    [[ -n "${origin-}" ]] && source_origin="${origin-}"

    # Check if sourced_file is already sourced
    # (ie. is listed in sourced_files)
    if [[ " ${sourced_files[*]-} " == *" ${sourced_file-} "* ]]; then
      # If already sourced, skip to next line.
      cecho 'INFO' "${indent}${indent_string}${sourced_file##*/} skipped." >&"${error_fd-2}"
      continue
    fi

    # Add file to sourced list,
    sourced_files+=("${sourced_file-}")

    # Write sourced file contents to output.
    cecho 'DEBUG' "Debug: including file '${sourced_file}' in output." >&"${verbose_fd-2}"

    if ! include-sources ${options[@]+"${options[@]}"} \
        ${include_options[@]+"${include_options[@]}"} \
        --level=$((level + 1)) \
        --origin="${source_origin-}" \
        --output="${output-}" \
        "${sourced_file-}"; then
      if [[ -z "${origin-}" ]]; then
        cecho "ERROR" "Error: failed during assembly of file '${input-}'." >&"${error_fd-2}"
      else
        cecho "ERROR" "Error: failed including file '${source_origin-}' in '${input-}'." >&"${error_fd-2}"
      fi
      close-fds
      return 1
    fi

  done < "${input-}"

  cecho "DEBUG" "Debug: end of file '${input-}' processing." >&"${verbose_fd-2}"

  close-fds
  return 0
}
