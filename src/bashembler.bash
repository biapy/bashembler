#!/usr/bin/env bash
# @file src/bashembler.bash
# @author Pierre-Yves Landuré < contact at biapy dot fr >
# @brief build one-file bash script from multiple files source.
# @description
#     bashembler, contraction for bash-assembler build one-file bash script
#     by including assembled script and sourced scripts into an unique output
#     file.
#
#     Partially inspired by:
#     [Replacing 'source file' with its content, and expanding variables, in bash](https://stackoverflow.com/questions/37531927/replacing-source-file-with-its-content-and-expanding-variables-in-bash)

version="1.0.0"

# Test if file is sourced.
if ! (return 0 2> '/dev/null'); then
  # Apply The Sharat's recommendations
  # See [Shell Script Best Practices](https://sharats.me/posts/shell-script-best-practices/)
  set -o errexit
  set -o nounset
  set -o pipefail
  if [[ "${TRACE-0}" == "1" ]]; then
    set -o xtrace
  fi
  #cd "$(dirname "${0-}")"
fi

# shellcheck source-path=SCRIPTDIR
source "${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/cecho.bash"
source "${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/in-list.bash"
source "${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/realpath.bash"
source "${BASH_SOURCE[0]%/*}/internals/include-sources.bash"

# @description
#     bashembler, contraction for bash-assembler build one-file bash script
#     by including assembled script and sourced scripts into an unique output
#     file.
#     If available, resulting script is formated using shfmt
#     and checked using shellcheck.
#
# @example
#   source "${BASH_SOURCE[0]%/*}/libs/biapy-bashlings/src/bashembler.bash"
#   bashembler "src/my-script.bash" > 'bin/my-script'
#
# @option -h | -? | --help Display usage information.
# @option -V | --version Display version.
# @option -q | --quiet Disable error message output.
# @option -v | --verbose Enable verbose mode.
# @option -c | --discard-comments Remove comment lines from assembled file.
# @option -w | --overwrite Overwrite output path if it is an existing file.
# @option -o <output-path> | --output=<output-path> Write output to given path.
#
# @arg $1 string A `bash` (or `sh`) script file.
#
# @stdout The one-file version of the $1 script, with sourced files included.
# @stderr Error if argument is missing, or more than one argument provided.
# @stderr Error if output path exist, and --overwrite option is missing.
# @stderr Error if bashembler is unable to find a sourced file.
#
# @exitcode 0 If `bash`` script assembly is successful.
# @exitcode 1 If bashembler failed to assemble the script.
# @exitcode 1 If argument is missing, or more than one argument provided.
# @exitcode 1 If bashembler is unable to find a sourced file.
#
# @see [cecho](https://github.com/biapy/biapy-bashlings/blob/main/doc/cecho.md)
# @see [in-list](https://github.com/biapy/biapy-bashlings/blob/main/doc/in-list.md)
# @see [realpath](https://github.com/biapy/biapy-bashlings/blob/main/doc/realpath.md)
# @see [include-sources](./internals/include-sources.md#include-sources)
function bashembler() {
  local quiet=0
  local verbose=0
  local overwrite=0
  local discard_comments=0
  local input_path=''
  local output_path='-'
  local options
  declare -a options

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
  close-fds() {
    [[ "${error_fd-2}" -ne 2 ]] && eval "exec ${error_fd-}>&-"
    [[ "${verbose_fd-2}" -ne 2 ]] && eval "exec ${verbose_fd-}>&-"
  }

  # Bashembler usage.
  function usage() {
    cat << 'EOF'
Bashembler v${version}
Homepage: https://github.com/biapy/bashembler

bashembler assembles shell scripts splitted across multiple files into a
one-file script, ready for deployment. By default, bashembler output assembled
script on /dev/stdout. Use --output option to write assembled script to file.

Usage:

  bashembler [ -h | -? | --help ] [ -V | --version ] [ -q | --quiet ]
    [ -v | --verbose ] [ -c | --discard-comments ] [ -w | --overwrite]
    [ --o <final-script.bash> | --output=<final-script.bash> ]
    <splitted-script.bash>

Where:

  -h, -?, --help          Display usage information.
  -V, --version           Display version.
  -q, --quiet             Disable error message output.
  -v, --verbose           Enable verbose mode.
  -c, --discard-comments  Remove comment lines from assembled file.
  -w, --overwrite         Overwrite output path if it is an existing file.
  -o <output-path>, --output=<output-path>
                          Write output to given path.

EOF
  }

  while :; do
    case "${1-}" in
      '-h' | '-?' | '--help')
        # Display a usage synopsis.
        usage
        return 0
        ;;
      '-V' | '--version')
        echo "Bashembler v${version}"
        return 0
        ;;
      '-v' | '--verbose')
        verbose=1
        ;;
      '-q' | '--quiet')
        quiet=1
        ;;
      '-c' | '--discard-comments')
        discard_comments=1
        ;;
      '-w' | '--overwrite')
        overwrite=1
        ;;
      '-o' | '--output')
        # Takes an option argument; ensure it has been specified.
        if [[ -n "${2-}" ]]; then
            output_path="${2-}"
            shift
        else
          cecho 'ERROR' "Error: --output requires an non-empty option argument." >&"${error_fd-2}"
          close-fds
          return 1
        fi
        ;;
      '--output='?*)
        # Delete everything up to "=" and assign the remainder.
        output_path="${1#*=}"
        ;;
      '--output=')
        # Handle the case of an empty --file=
        cecho 'ERROR' "Error: --output requires an non-empty option argument." >&"${error_fd-2}"
        close-fds
        return 1
        ;;
      '--') # End of all options.
        shift
        break
        ;;
      '-'?*)
        cecho 'ERROR' "Error: option '${1}' is not recognized." >&"${error_fd-2}"
        close-fds
        return 1
        ;;
      *)
        # Default case: No more options, so break out of the loop.
        break
        ;;
    esac

    shift
  done

  if [[ ${#} -ne 1 ]]; then
    cecho "ERROR" "Error: ${FUNCNAME[0]} accept one and only one argument." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  input_path="${1-}"

  if [[ -z "${input_path}" ]]; then
    cecho "ERROR" "Error: ${FUNCNAME[0]} requires a valid file path as argument." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  if [[ "${output_path}" != '-' &&
        -e "${output_path}" &&
        "${overwrite}" -eq 0 ]]; then
    cecho "ERROR" "Error: output path '${output_path}' already exists. Use --overwrite to allow overwriting." >&"${error_fd-2}"
    close-fds
    return 1
  fi

  options=()
  [[ "${quiet-0}" -ne 0 ]] && options+=('--quiet')
  [[ "${verbose-0}" -ne 0 ]] && options+=('--verbose')
  [[ "${discard_comments-0}" -ne 0 ]] && options+=('--discard-comments')

  include-sources ${options[@]+"${options[@]}"} \
    --output="${output_path}" "${input_path}"
  result_code="${?}"

  close-fds
  return "${result_code}"
}

# Test if file is sourced.
# See [How to detect if a script is being sourced](https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced)
if ! (return 0 2> '/dev/null'); then
  # File is run as script. Call function as is.
  bashembler "${@}"
  exit ${?}
fi
