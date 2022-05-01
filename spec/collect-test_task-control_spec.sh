#shellcheck shell=sh

set -e

Describe 'collect-tests.sh'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'runs test task even if there are already the result of tests'
        Path summary-file=result/summary.txt
        project='prj-2000-selfAssertiveCleanTest'

        deploy_prj "$project" .
        (
            cd "$project"
            ./gradlew build < /dev/null > /dev/null 2>&1
        )

        # To ensure that if the test is accidentally executed again,
        # the execution time (in seconds) will be different from the previous time.
        %sleep 1

        # Keep the results that already exist for comparison.
        cp -p "$project/mod0/build/reports/tests/test/index.html" "index.html.old"

        When run collect-tests.sh -d result "$project"
        The status should equal 0
        The error should include 'TEST MESSAGE: cleanTest done!'
        The error should include ':mod0:test'

        The file "result/stdout" should not be empty directory
        The file "result/xml-report/__mod0.tgz" should be file
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0/index.html" should be exist

        # If retests have been done in the collect-tests,
        # there should be difference in the timestamps listed in the reports.
        Assert test -n "$(diff "result/test-report/__mod0/index.html" "index.html.old")"

        The file summary-file should be file
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SUCCESSFUL"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "passed"
        The word "$SUMMARY_FIELD_COUNT_PASS" of line 1 of contents of file summary-file should equal 2
        The word "$SUMMARY_FIELD_COUNT_FAIL" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_ERROR" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_SKIP" of line 1 of contents of file summary-file should equal 0
    End
End

Describe '--skip-tests;'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    Example 'If there is no result of tests and --skip-tests is specified, cannot collect result.'
        Path summary-file=result/summary.txt
        project='prj-1000-1100-brokenCleanTest'

        deploy_prj "$project" .

        When run collect-tests.sh --skip-tests -d result "$project"
        The status should equal 0
        The error should not include 'Deleting the cache of test result'
        The error should include 'The tests are skipped'
        The error should not include ':mod0:test'
        The error should not include ':mod1:test'

        The file "result/stdout" should be empty directory
        The file "result/xml-report" should be empty directory
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0" should not be exist
        The file "result/test-report/__mod1" should not be exist

        The file summary-file should be file
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SKIPPED"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "NO-RESULT"
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 2 of contents of file summary-file should equal ":mod1"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 2 of contents of file summary-file should equal "SKIPPED"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 2 of contents of file summary-file should equal "null"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 2 of contents of file summary-file should equal "NO-RESULT"
    End

    Example 'If there is already result of tests and --skip-tests is specified, collect existing result.'
        Path summary-file=result/summary.txt
        project='prj-2000-brokenCleanTest'

        deploy_prj "$project" .
        (
            cd "$project"
            ./gradlew build < /dev/null > /dev/null 2>&1
        )

        # To ensure that if the test is accidentally executed again,
        # the execution time (in seconds) will be different from the previous time.
        %sleep 1

        # Keep the results that already exist for comparison.
        cp -p "$project/mod0/build/reports/tests/test/index.html" "index.html.old"

        When run collect-tests.sh --skip-tests -d result "$project"
        The status should equal 0
        The error should not include 'Deleting the cache of test result'
        The error should include 'The tests are skipped'
        The error should not include ':mod0:test'

        The file "result/stdout" should be empty directory
        The file "result/xml-report" should not be empty directory
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0/index.html" should be file

        # If no retests have been done in the collect-tests,
        # there should be no difference in the timestamps listed in the reports.
        Assert test -z "$(diff "result/test-report/__mod0/index.html" "index.html.old")"

        The file summary-file should be file
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SKIPPED"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "passed"
        The word "$SUMMARY_FIELD_COUNT_PASS" of line 1 of contents of file summary-file should equal 2
        The word "$SUMMARY_FIELD_COUNT_FAIL" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_ERROR" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_SKIP" of line 1 of contents of file summary-file should equal 0
    End
End

Describe '--run-only-updated;'
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    Example 'If there is no result of tests and --run-only-updated is specified, run tests and collect result.'
        Path summary-file=result/summary.txt
        project='prj-1000-1100-brokenCleanTest'

        deploy_prj "$project" .

        When run collect-tests.sh --run-only-updated -d result "$project"
        The status should equal 0
        The error should not include 'Deleting the cache of test result'
        The error should include ':mod0:test'
        The error should include ':mod1:test'

        The file "result/stdout" should not be empty directory
        The file "result/xml-report/__mod0.tgz" should be file
        The file "result/xml-report/__mod1.tgz" should be file
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0/index.html" should be exist
        The file "result/test-report/__mod1/index.html" should be exist

        The file summary-file should be file
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SUCCESSFUL"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "null"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "passed"
        The word "$SUMMARY_FIELD_COUNT_PASS" of line 1 of contents of file summary-file should equal 1
        The word "$SUMMARY_FIELD_COUNT_FAIL" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_ERROR" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_SKIP" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 2 of contents of file summary-file should equal ":mod1"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 2 of contents of file summary-file should equal "FAILED"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 2 of contents of file summary-file should equal "FAILED"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 2 of contents of file summary-file should equal "failed"
        The word "$SUMMARY_FIELD_COUNT_PASS" of line 2 of contents of file summary-file should equal 1
        The word "$SUMMARY_FIELD_COUNT_FAIL" of line 2 of contents of file summary-file should equal 1
        The word "$SUMMARY_FIELD_COUNT_ERROR" of line 2 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_SKIP" of line 2 of contents of file summary-file should equal 0
    End

    Example 'If there is already result of tests and --run-only-updated is specified, collect existing result.'
        Path summary-file=result/summary.txt
        project='prj-2000-brokenCleanTest'

        deploy_prj "$project" .
        (
            cd "$project"
            ./gradlew build < /dev/null > /dev/null 2>&1
        )

        # To ensure that if the test is accidentally executed again,
        # the execution time (in seconds) will be different from the previous time.
        %sleep 1

        # Keep the results that already exist for comparison.
        cp -p "$project/mod0/build/reports/tests/test/index.html" "index.html.old"

        When run collect-tests.sh --run-only-updated -d result "$project"
        The status should equal 0
        The error should not include 'Deleting the cache of test result'
        The error should include ':mod0:test'

        The file "result/stdout" should not be empty directory
        The file "result/xml-report/__mod0.tgz" should be file
        The file "result/test-report/index.html" should be file
        The file "result/test-report/__mod0/index.html" should be exist

        # If no retests have been done in the collect-tests,
        # there should be no difference in the timestamps listed in the reports.
        Assert test -z "$(diff "result/test-report/__mod0/index.html" "index.html.old")"

        The file summary-file should be file
        The word "$SUMMARY_FIELD_PROJECT_NAME" of line 1 of contents of file summary-file should equal ":mod0"
        The word "$SUMMARY_FIELD_BUILD_STATUS" of line 1 of contents of file summary-file should equal "SUCCESSFUL"
        The word "$SUMMARY_FIELD_TASK_STATUS" of line 1 of contents of file summary-file should equal "UP-TO-DATE"
        The word "$SUMMARY_FIELD_TEST_STATUS" of line 1 of contents of file summary-file should equal "passed"
        The word "$SUMMARY_FIELD_COUNT_PASS" of line 1 of contents of file summary-file should equal 2
        The word "$SUMMARY_FIELD_COUNT_FAIL" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_ERROR" of line 1 of contents of file summary-file should equal 0
        The word "$SUMMARY_FIELD_COUNT_SKIP" of line 1 of contents of file summary-file should equal 0
    End
End
