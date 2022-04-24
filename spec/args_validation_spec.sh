#shellcheck shell=sh

set -e

Describe 'Validation of collect-tests.sh'
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

    It 'denies a call without -d option'
        When run collect-tests.sh gradle-example
        The status should equal 1
        The output should equal ''
        The error should start with "Usage: collect-tests.sh"
    End

    It 'denies a call with more than one -d option'
        When run collect-tests.sh -d result -d result gradle-example
        The status should equal 1
        The output should equal ''
        The error should start with "Usage: collect-tests.sh"
    End

    It 'denies a call without project path'
        When run collect-tests.sh -d result
        The status should equal 1
        The output should equal ''
        The error should start with "Usage: collect-tests.sh"
    End
End
