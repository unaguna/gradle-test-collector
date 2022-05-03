#shellcheck shell=sh

set -e

Describe 'the main project directory given for collect-tests.sh' main_project_dir
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'should exist'
        project='prj'

        # deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # The main project directory is not exist; it is illegal state.
        test ! -e "$project"

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "gradle project not found"
        The error should include "No such directory"
        The file "$TEST_LOG" should be empty file
    End

    It 'should be directory'
        project='prj-non-dir'

        # deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # The main project directory is not directory; it is illegal state.
        touch "$project"

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "gradle project not found"
        The error should include "It is not directory"
        The file "$TEST_LOG" should be empty file
    End

    It 'should contain gradlew'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # gradlew not exists; it is illegal state.
        rm -f "$project/gradlew"

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "cannot find gradle wrapper"
        The error should include "No such file"
        The file "$TEST_LOG" should be empty file
    End

    It 'should contain gradlew'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # gradlew is directory; it is illegal state.
        rm -f "$project/gradlew"
        mkdir "$project/gradlew"

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "cannot find gradle wrapper"
        The error should include "It is directory"
        The file "$TEST_LOG" should be empty file
    End

    It 'should contain executable gradlew'
        project='prj-1000-1100'

        deploy_prj "$project" .
        deploy_init_script 'test-log.gradle'
        export TEST_LOG="$TESTCASE_HOME/test.log"
        touch "$TEST_LOG"

        # gradlew is not executable; it is illegal state.
        chmod -x "$project/gradlew"

        When run collect-tests.sh -d result "$project"
        The status should equal 1
        The output should equal ''
        The error should include "cannot find gradle wrapper"
        The error should include "Non-executable"
        The file "$TEST_LOG" should be empty file
    End
End
