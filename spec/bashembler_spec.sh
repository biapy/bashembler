#!/bin/bash
# shellcheck shell=bash
# spec/bashembler_spec.bash
# Test src/internal/bashembler.bash:bashembler function.

Describe 'bashembler'
    Set 'errexit:on' 'pipefail:on' 'nounset:on'
    Include 'src/bashembler.bash'

    Describe 'is expected to fail: It'

        function setup-failure-tests() {
            output_file="$(mktemp)"
            export output_file
        }

        function cleanup-failure-tests() {
            [[ -e "${output_file}" ]] && rm "${output_file}"

            return 0
        }

        BeforeAll 'setup-failure-tests'
        AfterAll 'cleanup-failure-tests'

        It "fails when no argument is given"
            When call bashembler
            The status should be failure
            The output should equal ""
            The error should equal "Error: bashembler accept one and only one argument."
        End

        It "fails quietly when no argument is given"
            When call bashembler --quiet
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when more than one argument is given"
            When call bashembler 'argument 1' 'argument 2'
            The status should be failure
            The output should equal ""
            The error should equal "Error: bashembler accept one and only one argument."
        End

        It "fails quietly when more than one argument is given"
            When call bashembler --quiet 'argument 1' 'argument 2'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when an unsupported option is given"
            When call bashembler --unsupported 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal "Error: option '--unsupported' is not recognized."
        End

        It "fails quietly when an unsupported option is given"
            When call bashembler --quiet --unsupported 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when --output option is used without argument"
            When call bashembler --output
            The status should be failure
            The output should equal ""
            The error should equal "Error: --output requires an non-empty option argument."
        End

        It "fails when --output option is used without argument"
            When call bashembler --output= 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal "Error: --output requires an non-empty option argument."
        End

        It "fails quietly when --output option is used without argument"
            When call bashembler --quiet --output= 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when input file is an empty string."
            When call bashembler ''
            The status should be failure
            The output should equal ""
            The error should equal "Error: bashembler requires a valid file path as argument."
        End

        It "fails when input file does not exists."
            When call bashembler 'missing-file.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: file 'missing-file.bash' does not exists."
        End

        It "fails quietly when input file does not exists."
            When call bashembler --quiet 'missing-file.bash'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "accepts files starting by '-'."
            When call bashembler -- -missing-file.bash
            The status should be failure
            The output should equal ""
            The error should equal "Error: file '-missing-file.bash' does not exists."
        End

        It "fails when output file directory does not exists."
            When call bashembler --output='missing-directory/output-file.bash' 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: file 'missing-directory/output-file.bash' directory does not exists."
        End

        It "fails quietly when output file directory does not exists."
            When call bashembler --quiet --output='missing-directory/output-file.bash' 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when output file already exists."
            When call bashembler --output="${output_file}" 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: output path '${output_file}' already exists. Use --overwrite to allow overwriting."
        End
    End

    Describe 'is expected to succeed: It'

        setup-working-tests() {
            setup-sourcing-tests
            return 0
        }

        cleanup-working-tests() {
            cleanup-sourcing-tests
            return 0
        }

        BeforeAll 'setup-working-tests'
        AfterAll 'cleanup-working-tests'

        reset-output() {
            [[ -e "${output_file}" ]] && rm "${output_file}"
            # shellcheck disable=SC2154
            [[ -e "${existing_output_file}" ]] && echo "" > "${existing_output_file}"

            return 0
        }

        AfterEach 'reset-output'

        Describe "display version when"
            Parameters:matrix
                '--version' '-V'
            End

            Example "${1} is given."
                When call bashembler "${1}"
                The status should be success
                The output should start with "Bashembler v"
                The error should equal ""
            End
        End

        Describe "display usage when"
            Parameters:matrix
                '--help' '-h' '-?'
            End

            Example "${1} is given."
                When call bashembler "${1}"
                The status should be success
                The line 4 of output should equal "bashembler assembles shell scripts splitted across multiple files into a"
                The error should equal ""
            End
        End

        Describe "display debug information when"
            Parameters:matrix
                '--verbose' '-v'
            End

            Example "${1} is given."
                # shellcheck disable=SC2154
                When call bashembler "${1}" "${origin_file}"
                The status should be success
                The line 1 of output should equal "#!/bin/bash"
                The line 1 of error should equal "Debug: Verbose mode enabled in bashembler."
            End
        End

        It "includes sourced file into output."
            When call bashembler "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            # shellcheck disable=SC2154
            The line 2 of error should equal " | ${sourced_file##*/}"
        End

        It "accepts '-' as output path."
            When call bashembler --output=- "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End

        It "includes sourced file into output quietly."
            When call bashembler --quiet "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The error should equal ""
        End

        Describe "allows to specify output file using"
            Parameters:matrix
                '--output=' '--output ' '-o '
            End

            Example "${1}."
                Path output-file="${output_file}"
                # shellcheck disable=SC2086 # Word splitting is needed.
                When call bashembler ${1}"${output_file}" "${origin_file}"
                The status should be success
                The output should equal ""
                The file output-file should be exist
                The line 1 of file output-file contents should equal "#!/bin/bash"
                The line 2 of file output-file contents should equal '# Origin file contents'
                The line 3 of file output-file contents should equal 'echo "The origin file contents."'
                The line 4 of file output-file contents should equal '# Sourced file contents'
                The line 5 of file output-file contents should equal 'echo "The sourced file contents."'
                The line 1 of error should equal "Assembling ${origin_file}"
                The line 2 of error should equal " | ${sourced_file##*/}"
            End
        End
    
        Describe 'overwrite output file when'
            Parameters:matrix
                '--overwrite' '-w'
            End

            Example "${1} is given."
                Path output-file="${existing_output_file}"
                When call bashembler "${1}" --output="${existing_output_file}" "${origin_file}"
                The status should be success
                The output should equal ""
                The file output-file should be exist
                The line 1 of file output-file contents should equal "#!/bin/bash"
                The line 2 of file output-file contents should equal '# Origin file contents'
                The line 3 of file output-file contents should equal 'echo "The origin file contents."'
                The line 4 of file output-file contents should equal '# Sourced file contents'
                The line 5 of file output-file contents should equal 'echo "The sourced file contents."'
                The line 1 of error should equal "Assembling ${origin_file}"
                The line 2 of error should equal " | ${sourced_file##*/}"
            End
        End

        Describe 'discard comments when '
            Parameters:matrix
                '--discard-comments' '-c'
            End

            Example "${1} is given."
                When call bashembler "${1}" "${origin_file}"
                The status should be success
                The line 1 of output should equal "#!/bin/bash"
                The line 2 of output should equal 'echo "The origin file contents."'
                The line 3 of output should equal 'echo "The sourced file contents."'
                The line 1 of error should equal "Assembling ${origin_file}"
                The line 2 of error should equal " | ${sourced_file##*/}"
            End
        End
    End
End
