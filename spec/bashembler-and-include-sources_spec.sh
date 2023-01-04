#!/bin/bash
# shellcheck shell=bash
# spec/bashembler-and-include-sources_spec.bash
# Test src/internal/include-sources.bash:include-sources function
# and src/internal/bashembler.bash:bashembler function.

Describe 'bashembler & include-sources'
    Set 'errexit:on' 'pipefail:on' 'nounset:on'
    Include 'src/internals/include-sources.bash'
    Include 'src/bashembler.bash'

    Describe 'are expected to succeed:'

        setup() {
            setup-sourcing-tests
            return 0
        }

        cleanup() {
            cleanup-sourcing-tests
            return 0
        }

        BeforeAll 'setup'
        AfterAll 'cleanup'

        reset-output() {
            [[ -e "${output_file-}" ]] && rm "${output_file-}"

            return 0
        }

        AfterEach 'reset-output'

        Parameters:matrix
            'include-sources' 'bashembler'
        End

        It "fails when output path is not writeable."
            # shellcheck disable=SC2154 # readonly_output_path is assigned in spec_helper.sh
            When call bashembler --output="${readonly_output_path-}/output.sh" 'src/bashembler.bash'
            The status should be failure
            The status should equal 4
            The output should equal ""
            The error should equal "Error: error while initializing '${readonly_output_path-}/output.sh'."
        End

        It "fails quietly when output path is not writeable."
            # shellcheck disable=SC2154 # readonly_output_path is assigned in spec_helper.sh
            When call bashembler --quiet --output="${readonly_output_path-}/output.sh" 'src/bashembler.bash'
            The status should be failure
            The status should equal 4
            The output should equal ""
            The error should equal ""
        End

        It "${1} includes sourced file into output."
            # shellcheck disable=SC2154
            When call "${1}" "${origin_file}"
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

        It "${1} includes sourced file into output quietly."
            When call "${1}" --quiet "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The error should equal ""
        End

        It "${1} accepts '-' as output path."
            When call "${1}" --output=- "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End

        It "${1} discard comments and write output to file."
            Path output-file="${output_file}"
            When call "${1}" --discard-comments --output="${output_file}" "${origin_file}"
            The status should be success
            The line 1 of file output-file contents should equal "#!/bin/bash"
            The line 2 of file output-file contents should equal 'echo "The origin file contents."'
            The line 3 of file output-file contents should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End
    
        It "${1} ignore circular sourcing."
            # shellcheck disable=SC2154
            When call "${1}" "${infinite_sourcing_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The infinite sourcing file contents."'
            The line 3 of output should equal 'echo "This file source itself infinitely."'
            The line 1 of error should equal "Assembling ${infinite_sourcing_file}"
            # shellcheck disable=SC2154
            The line 2 of error should equal " | ${circular_sourcing_file##*/}"
            The line 3 of error should equal " |  | ${circular_sourcing_file##*/} skipped."
        End

        It "${1} fails when a source is missing."
            # shellcheck disable=SC2154
            When call "${1}" "${broken_sourcing_file}"
            The status should be failure
            The status should equal 6
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The broken script sourcing file contents."'
            The line 1 of error should equal "Assembling ${broken_sourcing_file}"
            # shellcheck disable=SC2154
            The line 2 of error should equal " | ${source_missing_file##*/}"
            # shellcheck disable=SC2154
            The line 3 of error should equal "Error: can not resolve command 'source \"${missing_target_file}\"' in file '${source_missing_file}'."
            The line 4 of error should equal "Error: failed during assembly of file '${broken_sourcing_file}'."
        End
    End
End

