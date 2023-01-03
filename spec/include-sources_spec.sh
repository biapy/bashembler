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
            The status should equal 2
            The output should equal ""
            The error should equal "Error: include-sources requires one and only one argument."
        End

        It "fails quietly when no argument is given"
            When call include-sources --quiet
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal ""
        End

        It "fails when more than one argument is given"
            When call include-sources 'argument 1' 'argument 2'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal "Error: include-sources requires one and only one argument."
        End

        It "fails quietly when more than one argument is given"
            When call include-sources --quiet 'argument 1' 'argument 2'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal ""
        End

        It "fails when an unsupported option is given"
            When call include-sources --unsupported 'argument 1'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal "Error: option '--unsupported' is not recognized."
        End

        It "fails quietly when an unsupported option is given"
            When call include-sources --quiet --unsupported 'argument 1'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal ""
        End

        It "fails when --origin option is used without argument"
            When call include-sources --origin 'argument 1'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal "Error: --origin requires an argument."
        End

        It "fails quietly when --origin option is used without argument"
            When call include-sources --quiet --origin 'argument 1'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal ""
        End

        It "fails when --level option is used without argument"
            When call include-sources --level 'argument 1'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal "Error: --level requires an argument."
        End

        It "fails quietly when --level option is used without argument"
            When call include-sources --quiet --level 'argument 1'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal ""
        End

        It "fails when --level option argument is not an integer"
            When call include-sources --level=a 'argument 1'
            The status should be failure
            The status should equal 3
            The output should equal ""
            The error should equal "Error: --level value is not an integer."
        End

        It "fails quietly when --level option argument is not an integer"
            When call include-sources --quiet --level=a 'argument 1'
            The status should be failure
            The status should equal 3
            The output should equal ""
            The error should equal ""
        End

        It "fails when --level option is used without --origin"
            When call include-sources --level=1 'src/bashembler.bash'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal "Error: --level option requires --origin to be specified."
        End

        It "fails quietly when --level option is used without --origin"
            When call include-sources --quiet --level=1 'src/bashembler.bash'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal ""
        End

        It "fails when --output option is used without argument"
            When call include-sources --output 'src/bashembler.bash'
            The status should be failure
            The status should equal 2
            The output should equal ""
            The error should equal "Error: --output requires an argument."
        End

        It "fails when input file does not exists."
            When call include-sources 'missing-file.bash'
            The status should be failure
            The status should equal 4
            The output should equal ""
            The error should equal "Error: file 'missing-file.bash' does not exists."
        End

        It "fails quietly when input file does not exists."
            When call include-sources --quiet 'missing-file.bash'
            The status should be failure
            The status should equal 4
            The output should equal ""
            The error should equal ""
        End

        It "fails when output file directory does not exists."
            When call include-sources --output='missing-directory/output-file.bash' 'src/bashembler.bash'
            The status should be failure
            The status should equal 5
            The output should equal ""
            The error should equal "Error: file 'missing-directory/output-file.bash' directory does not exists."
        End

        It "fails quietly when output file directory does not exists."
            When call include-sources --quiet --output='missing-directory/output-file.bash' 'src/bashembler.bash'
            The status should be failure
            The status should equal 5
            The output should equal ""
            The error should equal ""
        End
    End
End

