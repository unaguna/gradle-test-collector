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

  mkdir "$target/$prj_name"
  find "$SHELLSPEC_PROJECT_ROOT/spec/resources/prj-base" \
    "$SHELLSPEC_PROJECT_ROOT/spec/resources/$prj_name" \
    -mindepth 1 -maxdepth 1 -print0 | \
  xargs -0 -I {} cp -pr {} "$target/$prj_name"
}