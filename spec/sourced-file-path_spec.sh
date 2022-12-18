#!/bin/bash
# shellcheck shell=bash
# spec/sourced-file-path_spec.bash
# Test src/internal/sourced-file-path.bash:sourced-file-path function.

Describe 'sourced-file-path'
    Set 'errexit:on' 'pipefail:on' 'nounset:on'
    Include 'src/internals/sourced-file-path.bash'

    It "fails when no argument is given"
        When call sourced-file-path
        The status should be failure
        The output should equal ""
        The error should equal "Error: sourced-file-path requires one and only one argument."
    End

    It "fails quietly when no argument is given"
        When call sourced-file-path --quiet
        The status should be failure
        The output should equal ""
        The error should equal ""
    End

    It "fails when more than one argument is given"
        When call sourced-file-path 'argument 1' 'argument 2'
        The status should be failure
        The output should equal ""
        The error should equal "Error: sourced-file-path requires one and only one argument."
    End

    It "fails quietly when more than one argument is given"
        When call sourced-file-path --quiet 'argument 1' 'argument 2'
        The status should be failure
        The output should equal ""
        The error should equal ""
    End

    It "fails when an unsupported option is given"
        When call sourced-file-path --unsupported 'argument 1'
        The status should be failure
        The output should equal ""
        The error should equal "Error: option '--unsupported' is not recognized."
    End

    It "fails quietly when an unsupported option is given"
        When call sourced-file-path --quiet --unsupported 'argument 1'
        The status should be failure
        The output should equal ""
        The error should equal ""
    End

    It "fails when --origin option is used without argument"
        When call sourced-file-path --origin 'argument 1'
        The status should be failure
        The output should equal ""
        The error should equal "Error: --origin requires an argument."
    End

    It "fails quietly when --origin option is used without argument"
        When call sourced-file-path --quiet --origin 'argument 1'
        The status should be failure
        The output should equal ""
        The error should equal ""
    End

    It "fails when source command is badly formated"
        When call sourced-file-path 'soucre "file.bash"'
        The status should be failure
        The output should equal ""
        The error should equal "Error: unable to extract file from command 'soucre \"file.bash\"'."
    End

    It "fails quietly when source command is badly formated"
        When call sourced-file-path --quiet 'soucre "file.bash"'
        The status should be failure
        The output should equal ""
        The error should equal ""
    End

    It "parses \`source \"\${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/cecho.bash\"\` with origin"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --origin='src/bashembler.bash' 'source "${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/cecho.bash"'
        The status should be success
        The output should equal "$(pwd -P || true)/lib/biapy-bashlings/src/cecho.bash"
        The error should equal ""
    End

    It "parses \`source '$(pwd -P || true)/lib/biapy-bashlings/src/cecho.bash'\` with origin"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --origin='src/bashembler.bash' "source '$(pwd -P || true)/lib/biapy-bashlings/src/cecho.bash'"
        The status should be success
        The output should equal "$(pwd -P || true)/lib/biapy-bashlings/src/cecho.bash"
        The error should equal ""
    End

    It "parses \`source \"internals/include-sources.bash\"\` with origin"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --origin='src/bashembler.bash' 'source "internals/include-sources.bash"'
        The status should be success
        The output should equal "$(pwd -P || true)/src/internals/include-sources.bash"
        The error should equal ""
    End

    It "fails parsing \`source \"\${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/missing-file.bash\"\` with origin"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --origin='src/bashembler.bash' 'source "${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/missing-file.bash"'
        The status should be failure
        The output should equal ""
        The error should equal "Error: sourced file '\${BASH_SOURCE[0]%/*}/../lib/biapy-bashlings/src/missing-file.bash' (real path '$(pwd -P || true)/lib/biapy-bashlings/src/missing-file.bash') does not exists."
    End

    It "fails parsing \`source \"internals/missing-file.bash\"\` with origin"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --origin='src/bashembler.bash' 'source "internals/missing-file.bash"'
        The status should be failure
        The output should equal ""
        The error should equal "Error: sourced file 'internals/missing-file.bash' (real path '$(pwd -P || true)/src/internals/missing-file.bash') does not exists."
    End

    It "fails parsing \`source \"missing-path/missing-file.bash\"\` with origin"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --origin='src/bashembler.bash' 'source "missing-path/missing-file.bash"'
        The status should be failure
        The output should equal ""
        The error should equal "Error: sourced file 'missing-path/missing-file.bash' does not exists."
    End

    It "output debug messages when --verbose is used"
        # shellcheck disable=SC2016 # allow ${BASH_SOURCE} in single quotes.
        When call sourced-file-path --verbose "source 'test.bash'"
        The status should be success
        The output should equal "test.bash"
        The line 1 of error should equal "Debug: sourced-file-path's verbose mode enabled."
        The line 2 of error should equal "Debug: Extracting file path from source command 'source 'test.bash''."
        The line 3 of error should equal "Debug: Detected file path 'test.bash'."
        The line 4 of error should equal "Debug: Sourced file origin was not provided."
    End

End

Describe 'sourced-file-path, when given variously formated input,'
    Set 'errexit:on' 'pipefail:on' 'nounset:on'
    Include 'src/internals/sourced-file-path.bash'

    Parameters:matrix
        '.' 'source'
        # shellcheck disable=SC2286 # Allow empty string at beginning of line.
        '' "'" '"'
        'spec_helper.sh' '../lib/biapy-bashlings/src/cecho.bash' "\${BASH_SOURCE[0]%/*}/../../lib/biapy-bashlings/src/cecho.bash" 'spaced\ filename.sh'
        # shellcheck disable=SC2286 # Allow empty string at beginning of line.
        '' ' ' '   '
    End

    It "parses \`${4}${1} ${4}${2}${3}${2}${4}\`"
        When call sourced-file-path "${4}${1} ${4}${2}${3}${2}${4}"
        The status should be success
        The output should equal "${3}"
        The error should equal ""
    End
End
