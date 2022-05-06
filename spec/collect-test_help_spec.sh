#shellcheck shell=sh

set -e

Describe 'collect-tests.sh' help
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'shows description when --help given'
        When run collect-tests.sh --help
        The status should equal 0
        The output should start with "Gradle Test Collector"
        The error should equal ''
    End

    It 'shows description when --help given even if others specified (1)'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        When run collect-tests.sh --help -d result "$project" 
        The status should equal 0
        The output should start with "Gradle Test Collector"
        The error should equal ''
        The file "$TEST_LOG" should be empty file
    End

    It 'shows description when --help given even if others specified (2)'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        When run collect-tests.sh -d result "$project" --help
        The status should equal 0
        The output should start with "Gradle Test Collector"
        The error should equal ''
        The file "$TEST_LOG" should be empty file
    End

    It 'shows description when --help given even if illegal argument is specified'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        When run collect-tests.sh --help --illegal-dummy
        The status should equal 0
        The output should start with "Gradle Test Collector"
        The error should equal ''
        The file "$TEST_LOG" should be empty file
    End
End
