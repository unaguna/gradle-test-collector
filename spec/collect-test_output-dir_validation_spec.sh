#shellcheck shell=sh

set -e

Describe 'the output directory of collect-tests.sh' output_dir
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'may not exist'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # The output directory is empty; it is legal state.
        test ! -e 'result'

        When run collect-tests.sh -d result "$project"
        The status should equal 0
        The output should equal ''
        The error should include 'Collecting the test results'
        The contents of file "$TEST_LOG" should include 'TEST LOG: :mod0:test done'
    End

    It 'may exist as long as it is empty'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # The output directory is empty; it is legal state.
        mkdir 'result'

        When run collect-tests.sh -d result "$project"
        The status should equal 0
        The output should equal ''
        The error should include 'Collecting the test results'
        The contents of file "$TEST_LOG" should include 'TEST LOG: :mod0:test done'
    End

    It 'should be empty when it exists'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # The output directory is not empty; it is illegal state.
        mkdir 'result'
        touch 'result/dummy'

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "cannot create output directory"
        The error should include "Non-empty directory exists"
        The file "$TEST_LOG" should be empty file
    End

    It 'should be directory when it exists'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # The output directory is not directory; it is illegal state.
        touch 'result'

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "cannot create output directory"
        The error should include "Non-directory file exists"
        The file "$TEST_LOG" should be empty file
    End
End
