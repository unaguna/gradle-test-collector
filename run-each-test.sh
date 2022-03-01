#!/usr/bin/env bash

################################################################################
# Error handling
################################################################################

set -eu
set -o pipefail

set -C


################################################################################
# Functions
################################################################################

function usage_exit () {
    echo "Usage:" "$(basename "$0") -d <output_directory> <main_project_directory>" 1>&2
    exit "$1"
}

# Output an information
#
# Because stdout is used as output of gradlew in this script,
# any messages should be output to stderr.
function echo_info () {
    echo "$SCRIPT_NAME: " "$@" >&2
}


################################################################################
# Constant values
################################################################################

# The current directory when this script started.
ORIGINAL_PWD=$(pwd)
readonly ORIGINAL_PWD
# The directory path of this script file
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
readonly SCRIPT_DIR
# The filename of this script file
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME

readonly GET_SUMMARY_SCRIPT="$SCRIPT_DIR/test-summary.sh"


################################################################################
# Analyze arguments
################################################################################
declare -i argc=0
declare -a argv=()
output_dir=
while (( $# > 0 )); do
    case $1 in
        -)
            ((++argc))
            argv=("${argv[@]}" "$1")
            shift
            ;;
        -*)
            if [[ "$1" == '-d' ]]; then
                output_dir="$2"
                shift
            else
                usage_exit 1
            fi
            shift
            ;;
        *)
            ((++argc))
            argv=("${argv[@]}" "$1")
            shift
            ;;
    esac
done
exit_code=$?
if [ $exit_code -ne 0 ]; then
    exit $exit_code
fi

if [ "$argc" -ne 1 ]; then
    usage_exit 1
fi

# (Required) The directory of main project, which contains build.gradle of root project.
readonly main_project_dir="${argv[0]}"

# (Required) Output destination directory path
if [ -n "${output_dir:-""}" ]; then
    output_dir=$(cd "$ORIGINAL_PWD"; cd "$(dirname "$output_dir")"; pwd)"/"$(basename "$output_dir")
    readonly output_dir
else
    usage_exit 1
fi


################################################################################
# main
################################################################################

cd "$main_project_dir"

readonly summary_path="$output_dir/summary.txt"
readonly stdout_dir="$output_dir/stdout"

# create the directory where output
if [ -n "$output_dir" ]; then
    mkdir -p "$output_dir"
fi
if [ -n "$stdout_dir" ]; then
    mkdir "$stdout_dir"
fi


# Disable UP-TO-DATE
task_name="cleanTest"
echo_info "Start '$task_name'"
./gradlew "$task_name" < /dev/null
echo_info "Completed '$task_name'"

# Read each build.gradle and output dependencies tree of it.
# cat ${ORIGINAL_PWD}/a.txt | while read -r project_file; do
find . -type d -name node_modules -prune -o -type f -name 'build.gradle*' -print | while read -r project_file; do
    project_dir=$(dirname "$project_file")
    project_name=$(sed -e "s|/|:|g" -e "s|^\.||" <<< "$project_dir")
    project_name_esc=${project_name//:/__}
    task_name="${project_name}:test"

    # Decide filepath where output.
    output_file="$stdout_dir/${project_name_esc:-"root"}.txt"

    echo_info "Start '$task_name'" 

    set +e
    # To solve the below problem, specify the redirect /dev/null to stdin:
    # https://ja.stackoverflow.com/questions/30942/シェルスクリプト内でgradleを呼ぶとそれ以降の処理がなされない
    ./gradlew --no-build-cache "$task_name" < /dev/null &> "$output_file"
    set -e

    echo_info "Completed '$task_name'" 
done


# Aggregate the test results
"$GET_SUMMARY_SCRIPT" -d "$output_dir" "$main_project_dir" | sort > "$summary_path"
