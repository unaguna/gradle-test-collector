#shellcheck shell=sh

set -e

Describe 'summary.txt, output of collect-tests.sh,'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'contains the count of test-cases'
        Path summary-file=result/summary.txt
        project='prj-4301-1204'

        deploy_prj "$project" .

        When run collect-tests.sh -d result "$project"
        The status should equal 0
        The error should include ':mod0:test'
        The error should include ':mod1:test'

        The file summary-file should be file
        The word 1 of line 1 of contents of file summary-file should equal ":mod0"
        The word 6 of line 1 of contents of file summary-file should equal 4
        The word 7 of line 1 of contents of file summary-file should equal 3
        The word 8 of line 1 of contents of file summary-file should equal 0
        The word 9 of line 1 of contents of file summary-file should equal 1
        The word 1 of line 2 of contents of file summary-file should equal ":mod1"
        The word 6 of line 2 of contents of file summary-file should equal 1
        The word 7 of line 2 of contents of file summary-file should equal 2
        The word 8 of line 2 of contents of file summary-file should equal 0
        The word 9 of line 2 of contents of file summary-file should equal 4
    End
End
