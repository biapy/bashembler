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

        It "fails when --output option is used without argument"
            When call include-sources --output 'argument 1'
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
            output_file="$(mktemp -u || true)"

            sourced_file="$(mktemp || true)"
            [[ -e "${sourced_file}" ]] && cat - > "${sourced_file}" << EOF
#!/bin/bash
echo "The sourced file contents."
EOF

            origin_file="$(mktemp || true)"
            [[ -e "${origin_file}" ]] && cat - > "${origin_file}" << EOF
#!/bin/bash
echo "The origin file contents."
source "${sourced_file}"
EOF

            circular_sourcing_file="$(mktemp || true)"
            [[ -e "${circular_sourcing_file}" ]] \
                && cat - > "${circular_sourcing_file}" << EOF
#!/bin/bash
source "${circular_sourcing_file##*/}"
echo "This file source itself infinitely."
EOF

            infinite_sourcing_file="$(mktemp || true)"
            [[ -e "${infinite_sourcing_file}" ]] \
                && cat - > "${infinite_sourcing_file}" << EOF
#!/bin/bash
echo "The infinite sourcing file contents."
source "${circular_sourcing_file}"
EOF

            source_missing_file="$(mktemp || true)"
            missing_target_file="missing-random-file-${source_missing_file##*/}"
            [[ -e "${source_missing_file}" ]] \
                && cat - > "${source_missing_file}" << EOF
#!/bin/bash
source "${missing_target_file}"
echo "This file source a missing file."
EOF

            broken_sourcing_file="$(mktemp || true)"
            [[ -e "${broken_sourcing_file}" ]] && cat - > "${broken_sourcing_file}" << EOF
#!/bin/bash
echo "The broken script sourcing file contents."
source "${source_missing_file}"
EOF

            return 0
        }

        cleanup() {
            [[ -e "${sourced_file}" ]] && rm "${sourced_file}"
            [[ -e "${origin_file}" ]] && rm "${origin_file}"
            [[ -e "${circular_sourcing_file}" ]] && rm "${circular_sourcing_file}"
            [[ -e "${infinite_sourcing_file}" ]] && rm "${infinite_sourcing_file}"
            [[ -e "${source_missing_file}" ]] && rm "${source_missing_file}"
            [[ -e "${broken_sourcing_file}" ]] && rm "${broken_sourcing_file}"

            return 0
        }

        BeforeAll 'setup'
        AfterAll 'cleanup'

        reset-output() {
            [[ -e "${output_file}" ]] && rm "${output_file}"

            return 0
        }

        AfterEach 'reset-output'

        It "includes sourced file into output."
            When call include-sources "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The origin file contents."'
            The line 3 of output should equal 'echo "The sourced file contents."'
            The error should equal "Info: file '${sourced_file}' included successfully."
        End

        It "includes sourced file into output quietly."
            When call include-sources --quiet "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The origin file contents."'
            The line 3 of output should equal 'echo "The sourced file contents."'
            The error should equal ""
        End

        It "fails quietly when output file directory does not exists."
            Path output-file="${output_file}"
            When call include-sources --output="${output_file}" "${origin_file}"
            The status should be success
            The output should equal ""
            The file output-file should be exist
            The line 1 of file output-file contents should equal "#!/bin/bash"
            The line 2 of file output-file contents should equal 'echo "The origin file contents."'
            The line 3 of file output-file contents should equal 'echo "The sourced file contents."'
            The error should equal "Info: file '${sourced_file}' included successfully."
        End

        It "breaks circular sourcing."
            When call include-sources "${infinite_sourcing_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The infinite sourcing file contents."'
            The line 3 of output should equal 'echo "This file source itself infinitely."'
            The line 1 of error should equal "Info: file '${circular_sourcing_file}' is already included."
            The line 2 of error should equal "Info: file '${circular_sourcing_file}' included successfully."
        End

        It "fails when a source is missing."
            When call include-sources "${broken_sourcing_file}"
            The status should be failure
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The broken script sourcing file contents."'
            The line 1 of error should equal "Error: can not resolve command 'source \"${missing_target_file}\"' in file '${source_missing_file}'."
            The line 2 of error should equal "Error: failed during assembly of file '${broken_sourcing_file}'."
        End
    End
End

