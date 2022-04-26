#shellcheck shell=sh

set -e

%const FIELD_PROJECT_NAME: 1
%const FIELD_BUILD_STATUS: 2
%const FIELD_TASK_STATUS: 3
%const FIELD_TEST_STATUS: 4
%const FIELD_COUNT_PASS: 6
%const FIELD_COUNT_FAIL: 7
%const FIELD_COUNT_ERROR: 8
%const FIELD_COUNT_SKIP: 9

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
        The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$FIELD_COUNT_PASS" of line 1 of contents of file summary-file should equal 4
        The word "$FIELD_COUNT_FAIL" of line 1 of contents of file summary-file should equal 3
        The word "$FIELD_COUNT_ERROR" of line 1 of contents of file summary-file should equal 0
        The word "$FIELD_COUNT_SKIP" of line 1 of contents of file summary-file should equal 1
        The word "$FIELD_PROJECT_NAME" of line 2 of contents of file summary-file should equal ":mod1"
        The word "$FIELD_COUNT_PASS" of line 2 of contents of file summary-file should equal 1
        The word "$FIELD_COUNT_FAIL" of line 2 of contents of file summary-file should equal 2
        The word "$FIELD_COUNT_ERROR" of line 2 of contents of file summary-file should equal 0
        The word "$FIELD_COUNT_SKIP" of line 2 of contents of file summary-file should equal 4
    End

    ExampleGroup 'status'
        Example 'when tests pass'
            Path summary-file=result/summary.txt
            project='prj-100-110'

            deploy_prj "$project" .

            When run collect-tests.sh -d result "$project"
            The status should equal 0
            The error should include ':mod0:test'

            The file summary-file should be file
            The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
            The word "$FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SUCCESSFUL"
            The word "$FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
            The word "$FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "passed"
        End

        Example 'when tests fail'
            Path summary-file=result/summary.txt
            project='prj-100-110'

            deploy_prj "$project" .

            When run collect-tests.sh -d result "$project"
            The status should equal 0
            The error should include ':mod1:test'

            The file summary-file should be file
            The word "$FIELD_PROJECT_NAME" of line 2 of contents of file summary-file should equal ":mod1"
            The word "$FIELD_BUILD_STATUS" of line 2 of contents of file summary-file should equal "FAILED"
            The word "$FIELD_TASK_STATUS" of line 2 of contents of file summary-file should equal "FAILED"
            The word "$FIELD_TEST_STATUS" of line 2 of contents of file summary-file should equal "failed"
        End

        Example 'when test task is skipped'
            Path summary-file=result/summary.txt
            project='prj-skipped'

            deploy_prj "$project" .

            When run collect-tests.sh -d result "$project"
            The status should equal 0
            The error should include ':mod0:test'

            The file summary-file should be file
            The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
            The word "$FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SUCCESSFUL"
            The word "$FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "SKIPPED"
            The word "$FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "NO-RESULT"
        End

        Example 'when test task has no source'
            Path summary-file=result/summary.txt
            project='prj-no-source'

            deploy_prj "$project" .

            When run collect-tests.sh -d result "$project"
            The status should equal 0
            The error should include ':mod0:test'

            The file summary-file should be file
            The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
            The word "$FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SUCCESSFUL"
            The word "$FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "NO-SOURCE"
            The word "$FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "NO-RESULT"
        End

        Example 'when test task does not exist'
            Path summary-file=result/summary.txt
            project='prj-no-task'

            deploy_prj "$project" .

            When run collect-tests.sh -d result "$project"
            The status should equal 0
            The error should include ':mod0:test'

            The file summary-file should be file
            The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
            The word "$FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "NO-TASK"
            The word "$FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
            The word "$FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "NO-TASK"
        End
    End
End
