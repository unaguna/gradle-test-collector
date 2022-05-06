#shellcheck shell=sh

set -e

Describe 'collect-tests.sh' output-version
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'shows the version of this tool'
        Path version-file=result/gtc-version.txt
        project='prj-1000-1100'

        deploy_prj "$project" .

        When run collect-tests.sh -d result "$project" 
        The status should equal 0
        The output should equal ''
        The error should include 'Collecting the test results'
        
        The file version-file should be exist
        The contents of file version-file should start with 'Gradle Test Collector'
    End

    It 'shows the version of this tool even if gradle task failed'
        Path version-file=result/gtc-version.txt
        project='prj-all-task-broken'

        deploy_prj "$project" .

        When run collect-tests.sh -d result "$project" 
        The status should equal 1
        The output should equal ''
        The error should include 'is broken for test'
        
        The file version-file should be exist
        The contents of file version-file should start with 'Gradle Test Collector'
    End

    It 'shows the version of gradle'
        Path version-file=result/gradle-version.txt
        project='prj-1000-1100'

        deploy_prj "$project" .

        When run collect-tests.sh -d result "$project" 
        The status should equal 0
        The output should equal ''
        The error should include 'Collecting the test results'
        
        The file version-file should be exist
        The contents of file version-file should include 'Gradle'
    End

    It 'shows the version of gradle even if gradle task failed'
        Path version-file=result/gradle-version.txt
        project='prj-all-task-broken'

        deploy_prj "$project" .

        When run collect-tests.sh -d result "$project" 
        The status should equal 1
        The output should equal ''
        The error should include 'is broken for test'
        
        The file version-file should be exist
        The contents of file version-file should include 'Gradle'
    End
End
