#shellcheck shell=sh

set -e

Describe 'summary.txt, output of collect-tests.sh,'
    BeforeAll 'install'
    AfterAll 'uninstall'
    BeforeEach 'setup'
    AfterEach 'clean'
    install() {
        # Build the application
        ./build.sh
        cd build/release
        archive="$(pwd)/$(find . -type f -name '*.tgz' | head -n1)"
        readonly archive

        # Create temporary directories
        app_dir=$(mktemp -d)
        readonly app_dir
        readonly app_install_dir="$app_dir/exe"
        readonly app_bin_dir="$app_dir/bin"
        mkdir "$app_install_dir" "$app_bin_dir"

        # Install the application (1/2)
        cd "$app_install_dir"
        tar -xzf "$archive"

        # Install the application (2/2)
        cd "$app_bin_dir"
        ln -s "$app_install_dir/collect-tests.sh" .
        PATH="$app_bin_dir:$PATH"
        export PATH
    }
    uninstall() {
        rm -Rf "$app_dir"
    }
    setup() {
        tmp_cd=$(mktemp -d)
        readonly tmp_cd
        cd "$tmp_cd"
    }
    clean() {
        rm -Rf "$tmp_cd"
    }
    deploy_prj() {
        prj_name="$1"
        target="$2"
        cp -pr "$SHELLSPEC_PROJECT_ROOT/spec/resources/$prj_name" "$target"
        cp -prT "$SHELLSPEC_PROJECT_ROOT/spec/resources/prj-base" "$target/$prj_name"
    }

    It 'contains results of all projects'
        Path summary-file=result/summary.txt

        deploy_prj prj-100-110 .

        When run collect-tests.sh -d result prj-100-110
        The status should equal 0
        The error should include ':mod0:test'
        The error should include ':mod1:test'

        The file summary-file should be file
        The word 1 of line 1 of contents of file summary-file should equal ":mod0"
        The word 2 of line 1 of contents of file summary-file should equal "SUCCESSFUL"
        The word 1 of line 2 of contents of file summary-file should equal ":mod1"
        The word 2 of line 2 of contents of file summary-file should equal "FAILED"
    End
End
