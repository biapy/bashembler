#!/bin/bash
# shellcheck shell=bash
# spec/bashembler_spec.bash
# Test src/internal/bashembler.bash:bashembler function.

Describe 'bashembler'
    Set 'errexit:on' 'pipefail:on' 'nounset:on'
    Include 'src/bashembler.bash'

    Describe 'expected failule'
        setup() {
            output_file="$(mktemp)"
        }

        cleanup() {
            [[ -e "${output_file}" ]] && rm "${output_file}"

            return 0
        }

        BeforeAll 'setup'
        AfterAll 'cleanup'

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

    Describe 'works'

        setup() {
            output_file="$(mktemp -u)"
            existing_output_file="$(mktemp)"

            sourced_file="$(mktemp || true)"
            [[ -e "${sourced_file}" ]] && cat - > "${sourced_file}" << EOF
#!/bin/bash
# Sourced file contents
echo "The sourced file contents."
EOF

            origin_file="$(mktemp || true)"
            [[ -e "${origin_file}" ]] && cat - > "${origin_file}" << EOF
#!/bin/bash
# Origin file contents
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
            [[ -e "${existing_output_file}" ]] && rm "${existing_output_file}"
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
            [[ -e "${existing_output_file}" ]] && echo "" > "${existing_output_file}"

            return 0
        }

        AfterEach 'reset-output'

        It "display version when -V is given."
            When call bashembler -V
            The status should be success
            The output should start with "Bashembler v"
            The error should equal ""
        End

        It "display version when --version is given."
            When call bashembler --version
            The status should be success
            The output should start with "Bashembler v"
            The error should equal ""
        End

        It "display usage when -h is given."
            When call bashembler -h
            The status should be success
            The line 4 of output should equal "bashembler assembles shell scripts splitted across multiple files into a"
            The error should equal ""
        End

        It "display usage when -? is given."
            When call bashembler -?
            The status should be success
            The line 4 of output should equal "bashembler assembles shell scripts splitted across multiple files into a"
            The error should equal ""
        End

        It "display usage when --help is given."
            When call bashembler --help
            The status should be success
            The line 4 of output should equal "bashembler assembles shell scripts splitted across multiple files into a"
            The error should equal ""
        End

        It "display debug information when -v is given."
            When call bashembler -v "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 1 of error should equal "Debug: Verbose mode enabled in bashembler."
        End

        It "display debug information when --verbose is given."
            When call bashembler --verbose "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 1 of error should equal "Debug: Verbose mode enabled in bashembler."
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

        It "allows to specify output file using -o."
            Path output-file="${output_file}"
            When call bashembler -o "${output_file}" "${origin_file}"
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

        It "allows to specify output file using --output."
            Path output-file="${output_file}"
            When call bashembler --output "${output_file}" "${origin_file}"
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

        It "allows to specify output file using --output=."
            Path output-file="${output_file}"
            When call bashembler --output="${output_file}" "${origin_file}"
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


        It "overwrite output file when -w is given."
            Path output-file="${existing_output_file}"
            When call bashembler -w --output="${existing_output_file}" "${origin_file}"
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

        It "overwrite output file when --overwrite is given."
            Path output-file="${existing_output_file}"
            When call bashembler --overwrite --output="${existing_output_file}" "${origin_file}"
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

        It "discard comments when --discard-comments is given."
            When call bashembler --discard-comments "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The origin file contents."'
            The line 3 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End

        It "discard comments when -c is given."
            When call bashembler -c "${origin_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The origin file contents."'
            The line 3 of output should equal 'echo "The sourced file contents."'
            The line 1 of error should equal "Assembling ${origin_file}"
            The line 2 of error should equal " | ${sourced_file##*/}"
        End
    
        It "ignore circular sourcing."
            When call bashembler "${infinite_sourcing_file}"
            The status should be success
            The line 1 of output should equal "#!/bin/bash"
            The line 2 of output should equal 'echo "The infinite sourcing file contents."'
            The line 3 of output should equal 'echo "This file source itself infinitely."'
            The line 1 of error should equal "Assembling ${infinite_sourcing_file}"
            The line 2 of error should equal " | ${circular_sourcing_file##*/}"
            The line 3 of error should equal " |  | ${circular_sourcing_file##*/} skipped."
        End

        It "fails when a source is missing."
            When call bashembler "${broken_sourcing_file}"
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
