#!/bin/bash
# shellcheck shell=bash
# spec/include-sources_spec.bash
# Test src/internal/include-sources.bash:include-sources function.

Describe 'include-sources'
    Set 'errexit:on' 'pipefail:on' 'nounset:on'
    Include 'src/internals/include-sources.bash'

    Describe 'expected failule'
        It "fails when no argument is given"
            When call include-sources
            The status should be failure
            The output should equal ""
            The error should equal "Error: include-sources requires one and only one argument."
        End

        It "fails quietly when no argument is given"
            When call include-sources --quiet
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when more than one argument is given"
            When call include-sources 'argument 1' 'argument 2'
            The status should be failure
            The output should equal ""
            The error should equal "Error: include-sources requires one and only one argument."
        End

        It "fails quietly when more than one argument is given"
            When call include-sources --quiet 'argument 1' 'argument 2'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when an unsupported option is given"
            When call include-sources --unsupported 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal "Error: option '--unsupported' is not recognized."
        End

        It "fails quietly when an unsupported option is given"
            When call include-sources --quiet --unsupported 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when --origin option is used without argument"
            When call include-sources --origin 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal "Error: --origin requires an argument."
        End

        It "fails quietly when --origin option is used without argument"
            When call include-sources --quiet --origin 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when --level option is used without argument"
            When call include-sources --level 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal "Error: --level requires an argument."
        End

        It "fails quietly when --level option is used without argument"
            When call include-sources --quiet --level 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when --level option argument is not an integer"
            When call include-sources --level=a 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal "Error: --level value is not an integer."
        End

        It "fails quietly when --level option argument is not an integer"
            When call include-sources --quiet --level=a 'argument 1'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when --level option is used without --origin"
            When call include-sources --level=1 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: --level option requires --origin to be specified."
        End

        It "fails quietly when --level option is used without --origin"
            When call include-sources --quiet --level=1 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when --output option is used without argument"
            When call include-sources --output 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: --output requires an argument."
        End

        It "fails when input file does not exists."
            When call include-sources 'missing-file.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: file 'missing-file.bash' does not exists."
        End

        It "fails quietly when input file does not exists."
            When call include-sources --quiet 'missing-file.bash'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End

        It "fails when output file directory does not exists."
            When call include-sources --output='missing-directory/output-file.bash' 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal "Error: file 'missing-directory/output-file.bash' directory does not exists."
        End

        It "fails quietly when output file directory does not exists."
            When call include-sources --quiet --output='missing-directory/output-file.bash' 'src/bashembler.bash'
            The status should be failure
            The output should equal ""
            The error should equal ""
        End
    End

    Describe 'works'

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

        It "includes sourced file into output."
            When call include-sources "${origin_file}"
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
            When call include-sources --quiet "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The error should equal ""
        End

        It "accepts '-' as output path."
            When call include-sources --output=- "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal '# Origin file contents'
            The line 3 of output should equal 'echo "The origin file contents."'
            The line 4 of output should equal '# Sourced file contents'
            The line 5 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End

        It "includes sourced file into output and write output to file."
            Path output-file="${output_file}"
            When call include-sources --output="${output_file}" "${origin_file}"
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

        It "discard comments."
            When call include-sources --discard-comments "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The origin file contents."'
            The line 3 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End
    
        It "ignore circular sourcing."
            When call include-sources "${infinite_sourcing_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The infinite sourcing file contents."'
            The line 3 of output should equal 'echo "This file source itself infinitely."'
            The line 1 of error should equal "Assembling ${infinite_sourcing_file}"
            The line 2 of error should equal " | ${circular_sourcing_file##*/}"
            The line 3 of error should equal " |  | ${circular_sourcing_file##*/} skipped."
        End

        It "fails when a source is missing."
            When call include-sources "${broken_sourcing_file}"
            The status should be failure
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The broken script sourcing file contents."'
            The line 1 of error should equal "Assembling ${broken_sourcing_file}"
            The line 2 of error should equal " | ${source_missing_file##*/}"
            The line 3 of error should equal "Error: can not resolve command 'source \"${missing_target_file}\"' in file '${source_missing_file}'."
            The line 4 of error should equal "Error: failed during assembly of file '${broken_sourcing_file}'."
        End
    End
End

