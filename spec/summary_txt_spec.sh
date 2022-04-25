#shellcheck shell=sh

set -e

Describe 'summary.txt, output of collect-tests.sh,'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'contains results of all projects'
        Path summary-file=result/summary.txt

        deploy_prj prj-100-110 .

        When run collect-tests.sh -d result prj-100-110
        The status should equal 0
        The error should include ':mod0:test'
        The error should include ':mod1:test'

        The file summary-file should be file
        The word 1 of line 1 of contents of file summary-file should equal ":mod0"
        The word 2 of line 1 of contents of file summary-file should equal "SUCCESSFUL"
        The word 1 of line 2 of contents of file summary-file should equal ":mod1"
        The word 2 of line 2 of contents of file summary-file should equal "FAILED"
    End
End
