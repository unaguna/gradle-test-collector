#!/usr/bin/env bash

################################################################################
# Error handling
################################################################################

set -eu
set -o pipefail


################################################################################
# Script information
################################################################################

# The current directory when this script started.
ORIGINAL_PWD=$(pwd)
readonly ORIGINAL_PWD
# The directory path of this script file
SCRIPT_DIR=$(cd "$(dirname "$0")"; pwd)
readonly SCRIPT_DIR
# The path of this script file
SCRIPT_NAME=$(basename "$0")
readonly SCRIPT_NAME


################################################################################
# Include
################################################################################

# shellcheck source=libs/ana-gradle.sh
source "$SCRIPT_DIR/libs/ana-gradle.sh"


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
            argv+=( "$1" )
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
            argv+=( "$1" )
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
# Temporally files
################################################################################

# All temporally files which should be deleted on exit
tmpfile_list=( )

function remove_tmpfile {
    set +e
    for tmpfile in "${tmpfile_list[@]}"
    do
        if [ -e "$tmpfile" ]; then
            rm -f "$tmpfile"
        fi
    done
    set -e
}
trap remove_tmpfile EXIT
trap 'trap - EXIT; remove_tmpfile; exit -1' INT PIPE TERM

# the output of `gradle projects`
tmp_project_list_path=$(mktemp)
readonly tmp_project_list_path
tmpfile_list+=( "$tmp_project_list_path" )


################################################################################
# main
################################################################################

cd "$main_project_dir"

readonly stdout_dir="$output_dir/stdout"

# create the directory where output
if [ -n "$output_dir" ]; then
    mkdir -p "$output_dir"
fi
if [ -n "$stdout_dir" ]; then
    mkdir "$stdout_dir"
fi

# Get sub-projects list
task_name="projects"
echo_info "Start '$task_name'"
./gradlew "$task_name" < /dev/null > "$tmp_project_list_path"
echo_info "Completed '$task_name'"

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

    # Even if the build.gradle file exists, 
    # ignore it if it is not recognized as a sub project by the root project.
    if ! is_sub_project "$project_name" "$tmp_project_list_path"; then
        continue
    fi

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
"$GET_SUMMARY_SCRIPT" -d "$output_dir" "$main_project_dir"
