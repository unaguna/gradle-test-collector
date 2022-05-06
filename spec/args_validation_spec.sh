#shellcheck shell=sh

set -e

Describe 'Validation of collect-tests.sh'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'denies a call without -d option'
        When run collect-tests.sh gradle-example
        The status should equal 1
        The output should equal ''
        The error should start with "Usage: collect-tests.sh"
    End

    It 'denies a call with more than one -d option'
        When run collect-tests.sh -d result -d result gradle-example
        The status should equal 1
        The output should equal ''
        The error should start with "Usage: collect-tests.sh"
    End

    It 'denies a call without project path'
        When run collect-tests.sh -d result
        The status should equal 1
        The output should equal ''
        The error should start with "Usage: collect-tests.sh"
    End
End
