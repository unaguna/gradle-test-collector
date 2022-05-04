#shellcheck shell=sh

set -e

Describe 'create-report-index' python create-report-index
    BeforeAll 'install_app'
    AfterAll 'uninstall_app'
    BeforeEach 'setup'
    AfterEach 'clean'

    It 'runs Mustache with a correct model'
        project='prj-1000-1100'
        report_dest='report'
        template_file='template-whole-prj-1000-1100'

        deploy_prj "$project" .
        collect-tests.sh -d result "$project" > /dev/null 2>&1

        cp "$RESOURCES_ROOT/index-template/$template_file" .

        mkdir "$report_dest"

        # Environment variables given for create-report-index.py
        export GRADLE_TEST_COLLECTOR_APP_NAME='STUB_APP_NAME'
        export GRADLE_TEST_COLLECTOR_URL='STUB_URL'
        export GRADLE_TEST_COLLECTOR_VERSION='STUB_VERSION'

        When run "$APP_INSTALL_DIR/libs/create-report-index.py" 'result/summary.txt' "$report_dest" \
            --template-index "$template_file" --template-top "$template_file"
        The status should equal 0
        The output should equal ''
        The error should equal ''

        The file "$report_dest/index.html" should be exist
        The file "$report_dest/top.html" should be exist
        Assert test -z "$(diff "$report_dest/index.html" "$report_dest/top.html")"

        The line 1 of contents of file "$report_dest/index.html" should equal "$GRADLE_TEST_COLLECTOR_APP_NAME"
        The line 2 of contents of file "$report_dest/index.html" should equal "$GRADLE_TEST_COLLECTOR_URL"
        The line 3 of contents of file "$report_dest/index.html" should equal "$GRADLE_TEST_COLLECTOR_VERSION"
        The line 4 of contents of file "$report_dest/index.html" should not equal ''
        The line 5 of contents of file "$report_dest/index.html" should not equal ''
        The line 6 of contents of file "$report_dest/index.html" should equal '3' # mod0, mod1, and root
        The line 7 of contents of file "$report_dest/index.html" should equal '2'
        The line 8 of contents of file "$report_dest/index.html" should equal '1'
        The line 9 of contents of file "$report_dest/index.html" should equal '0'
        The line 10 of contents of file "$report_dest/index.html" should equal '0'
        The line 11 of contents of file "$report_dest/index.html" should equal ':mod0'
        The line 12 of contents of file "$report_dest/index.html" should equal 'passed'
        The line 13 of contents of file "$report_dest/index.html" should equal 'True'
        The line 14 of contents of file "$report_dest/index.html" should equal '1'
        The line 15 of contents of file "$report_dest/index.html" should equal '1'
        The line 16 of contents of file "$report_dest/index.html" should equal '0'
        The line 17 of contents of file "$report_dest/index.html" should equal '0'
        The line 18 of contents of file "$report_dest/index.html" should equal '0'
        The line 19 of contents of file "$report_dest/index.html" should equal ':mod1'
        The line 20 of contents of file "$report_dest/index.html" should equal 'failed'
        The line 21 of contents of file "$report_dest/index.html" should equal 'True'
        The line 22 of contents of file "$report_dest/index.html" should equal '2'
        The line 23 of contents of file "$report_dest/index.html" should equal '1'
        The line 24 of contents of file "$report_dest/index.html" should equal '1'
        The line 25 of contents of file "$report_dest/index.html" should equal '0'
        The line 26 of contents of file "$report_dest/index.html" should equal '0'
        The line 27 of contents of file "$report_dest/index.html" should equal 'root'
        The line 28 of contents of file "$report_dest/index.html" should equal 'NO-SOURCE'
        The line 29 of contents of file "$report_dest/index.html" should equal 'False'
        The line 30 of contents of file "$report_dest/index.html" should equal ''
        The line 31 of contents of file "$report_dest/index.html" should equal ''
        The line 32 of contents of file "$report_dest/index.html" should equal ''
        The line 33 of contents of file "$report_dest/index.html" should equal ''
        The line 34 of contents of file "$report_dest/index.html" should equal ''
    End
End
