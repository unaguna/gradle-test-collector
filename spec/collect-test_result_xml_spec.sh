#shellcheck shell=sh

set -e

Describe 'result/xml-report' result
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'should be output when test tasks ran'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        When run collect-tests.sh -d result "$project"
        The status should equal 0
        The output should equal ''
        The error should include 'Collecting the test results'
        The contents of file "$TEST_LOG" should include 'TEST LOG: :mod0:test done'
        The contents of file "$TEST_LOG" should include 'TEST LOG: :mod1:test running'

        The file "result/xml-report/__mod0.tgz" should be file
        The file "result/xml-report/__mod1.tgz" should be file
    End
End