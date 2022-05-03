# shellcheck shell=sh

# Defining variables and functions here will affect all specfiles.
# Change shell options inside a function may cause different behavior,
# so it is better to set them here.
set -eu

# This callback function will be invoked only once before loading specfiles.
spec_helper_precheck() {
  # Available functions: info, warn, error, abort, setenv, unsetenv
  # Available variables: VERSION, SHELL_TYPE, SHELL_VERSION
  : minimum_version "0.29.0"
}

# This callback function will be invoked after a specfile has been loaded.
spec_helper_loaded() {
  :
}

# This callback function will be invoked after core modules has been loaded.
spec_helper_configure() {
  # Available functions: import, before_each, after_each, before_all, after_all
  : import 'support/custom_matcher'
}

export RESOURCES_ROOT="$SHELLSPEC_PROJECT_ROOT/spec/resources"

export SUMMARY_FIELD_PROJECT_NAME=1
export SUMMARY_FIELD_BUILD_STATUS=2
export SUMMARY_FIELD_TASK_STATUS=3
export SUMMARY_FIELD_TEST_STATUS=4
export SUMMARY_FIELD_COUNT_PASS=6
export SUMMARY_FIELD_COUNT_FAIL=7
export SUMMARY_FIELD_COUNT_ERROR=8
export SUMMARY_FIELD_COUNT_SKIP=9

install_app() {
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
uninstall_app() {
  rm -Rf "$app_dir"
}
setup() {
  TESTCASE_HOME=$(mktemp -d)
  readonly TESTCASE_HOME
  cd "$TESTCASE_HOME"

  export GRADLE_USER_HOME="$TESTCASE_HOME/gradle_user_home"
  mkdir "$GRADLE_USER_HOME"
}
clean() {
  rm -Rf "$TESTCASE_HOME"
}

deploy_prj() {
  prj_name="$1"
  target="$2"

  mkdir "$target/$prj_name"
  find "$RESOURCES_ROOT/prj-base" \
    "$RESOURCES_ROOT/$prj_name" \
    -mindepth 1 -maxdepth 1 -print0 | \
  xargs -0 -I {} cp -pr {} "$target/$prj_name"

  # rename resource files
  find "$target/$prj_name" -name '*.resource' | sed 'p;s/.resource$//' | xargs -n 2 mv
}

deploy_init_script() {
  test -d "$GRADLE_USER_HOME"

  init_d="$GRADLE_USER_HOME/init.d"

  rm -Rf "$init_d"
  mkdir "$init_d"
  if [ $# -gt 0 ]; then 
    (
      cd "$RESOURCES_ROOT/init.gradle"
      cp "$@" "$init_d"
    )
  fi
}
