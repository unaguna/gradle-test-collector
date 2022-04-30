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

Describe '--skip-tests;'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    Example 'If there is no result of tests and --skip-tests is specified, cannot collect result.'
        Path summary-file=result/summary.txt
        project='prj-100-110'

        deploy_prj "$project" .

        When run collect-tests.sh --skip-tests -d result "$project"
        The status should equal 0
        The error should include 'The tests are skipped'
        The error should not include ':mod0:test'
        The error should not include ':mod1:test'

        The file "result/stdout" should be empty directory
        The file "result/xml-report" should be empty directory
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0" should not be exist
        The file "result/test-report/__mod1" should not be exist

        The file summary-file should be file
        The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SKIPPED"
        The word "$FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
        The word "$FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "NO-RESULT"
        The word "$FIELD_PROJECT_NAME" of line 2 of contents of file summary-file should equal ":mod1"
        The word "$FIELD_BUILD_STATUS" of line 2 of contents of file summary-file should equal "SKIPPED"
        The word "$FIELD_TASK_STATUS" of line 2 of contents of file summary-file should equal "null"
        The word "$FIELD_TEST_STATUS" of line 2 of contents of file summary-file should equal "NO-RESULT"
    End

    Example 'If there is already result of tests and --skip-tests is specified, collect existing result.'
        Path summary-file=result/summary.txt
        project='prj-200'

        deploy_prj "$project" .
        (
            cd "$project"
            ./gradlew build < /dev/null > /dev/null 2>&1
        )

        When run collect-tests.sh --skip-tests -d result "$project"
        The status should equal 0
        The error should include 'The tests are skipped'
        The error should not include ':mod0:test'

        The file "result/stdout" should be empty directory
        The file "result/xml-report" should not be empty directory
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0/index.html" should be file

        The file summary-file should be file
        The word "$FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SKIPPED"
        The word "$FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
        The word "$FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "passed"
        The word "$FIELD_COUNT_PASS" of line 1 of contents of file summary-file should equal 2
        The word "$FIELD_COUNT_FAIL" of line 1 of contents of file summary-file should equal 0
        The word "$FIELD_COUNT_ERROR" of line 1 of contents of file summary-file should equal 0
        The word "$FIELD_COUNT_SKIP" of line 1 of contents of file summary-file should equal 0
    End
End
