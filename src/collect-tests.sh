#!/usr/bin/env bash

################################################################################
# Error handling
################################################################################

set -eu
set -o pipefail

set -C

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

# The version number of this application
GRADLE_TEST_COLLECTOR_VERSION=$(cat "$SCRIPT_DIR/.version")
export GRADLE_TEST_COLLECTOR_VERSION
readonly GRADLE_TEST_COLLECTOR_VERSION
# Application name
GRADLE_TEST_COLLECTOR_APP_NAME="Gradle Test Collector"
export GRADLE_TEST_COLLECTOR_APP_NAME
readonly GRADLE_TEST_COLLECTOR_APP_NAME
# Application URL
GRADLE_TEST_COLLECTOR_URL="https://github.com/unaguna/gradle-test-collector"
export GRADLE_TEST_COLLECTOR_URL
readonly GRADLE_TEST_COLLECTOR_URL


################################################################################
# Include
################################################################################

# shellcheck source=libs/ana-gradle.sh
source "$SCRIPT_DIR/libs/ana-gradle.sh"


################################################################################
# Functions
################################################################################

function usage_exit () {
    echo "Usage:" "$(basename "$0") -d <output_directory> [--run-only-updated|--skip-tests] <main_project_directory>" 1>&2
    exit "$1"
}

function echo_help () {
    echo "$GRADLE_TEST_COLLECTOR_APP_NAME $GRADLE_TEST_COLLECTOR_VERSION"
    echo ""
    echo "Usage:" "$(basename "$0") -d <output_directory> [--run-only-updated|--skip-tests] <main_project_directory>"
    echo ""
    echo "Options"
    echo "    -d <output_directory> :"
    echo "         (Required) Path of the directory where the results will be output."
    echo "    --run-only-updated :"
    echo "         If it is specified, tests that have already been run are NOT rerun."
    echo "    --skip-tests :"
    echo "         If it is specified, tests are not ran and the results of tests that"
    echo "         have already been run are collected."
    echo ""
    echo "Arguments"
    echo "    <main_project_directory> :"
    echo "         (Required) Path of the root directory of the gradle project."
}

# Output an information
#
# Because stdout is used as output of gradlew in this script,
# any messages should be output to stderr.
function echo_info () {
    echo "$SCRIPT_NAME: $*" >&2
}

# Output an error
#
# Because stdout is used as output of gradlew in this script,
# any messages should be output to stderr.
function echo_err() {
    echo "$SCRIPT_NAME: $*" >&2
}

# Output the name of the file to be used as the output destination for stdout of gradle task.
#
# Arguments
#   $1 - sub-project name
#
# Standard Output
#   the filename, not filepath
function stdout_filename() {
    local -r project_name=$1

    local -r project_name_esc=${project_name//:/__}

    echo "${project_name_esc:-"root"}.txt"
}

# Check if the specified string is a name of sub-project
#
# Arguments
#   $1: a string
#   $2: the path of the project table
#
# Returns
#   Returns 0 if the specified string is a name of sub-project.
#   Returns 1 otherwise.
function is_sub_project () {
    local -r sub_project_name=${1#:}
    local -r project_list_path=$2

    # The root project is not sub-project
    if [ -z "$sub_project_name" ]; then
        return 1
    fi

    set +e
    awk '{print $1}' "$project_list_path" | grep -e "^:${sub_project_name}$" &> /dev/null
    result=$?
    set -e

    if [ $result -ne 0 ] && [ $result -ne 1 ]; then
        echo_err "Failed to reference the temporary file created: $project_list_path"
        exit $result
    fi

    return $result
}

################################################################################
# Constant values
################################################################################

readonly PRINT_LINE_PY="$SCRIPT_DIR/libs/get-summary.py"

readonly CREATE_REPORT_INDEX="$SCRIPT_DIR/libs/create-report-index.py"

readonly INIT_GRADLE="$SCRIPT_DIR/libs/init.gradle"


################################################################################
# Analyze arguments
################################################################################
declare -i argc=0
declare -a argv=()
output_dir=
run_only_updated_flg=1
skip_tests_flg=1
help_flg=1
invalid_option_flg=1
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
            elif [[ "$1" == "--run-only-updated" ]]; then
                run_only_updated_flg=0
            elif [[ "$1" == "--skip-tests" ]]; then
                skip_tests_flg=0
            elif [[ "$1" == "--help" ]]; then
                help_flg=0
                # Ignore other arguments when displaying help
                break
            else
                # The option is illegal.
                # In some cases, such as when --help is specified, illegal options may be ignored,
                # so do not exit immediately, but only flag them.
                invalid_option_flg=0
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

if [ "$help_flg" -eq 0 ]; then
    echo_help
    exit 0
fi

if [ "$invalid_option_flg" -eq 0 ]; then
    usage_exit 1
fi

if [ "$argc" -ne 1 ]; then
    usage_exit 1
fi

if [ "$run_only_updated_flg" -eq 0 ] && [ "$skip_tests_flg" -eq 0 ]; then
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

# the output of `gradle tasks`
tmp_tasks_path=$(mktemp)
readonly tmp_tasks_path
tmpfile_list+=( "$tmp_tasks_path" )

# the list of HTML report
tmp_summary_path=$(mktemp)
readonly tmp_summary_path
tmpfile_list+=( "$tmp_summary_path" )


################################################################################
# main
################################################################################

cd "$main_project_dir"

readonly stdout_dir="$output_dir/stdout"
readonly summary_path="$output_dir/summary.txt"
readonly output_report_dir="$output_dir/test-report"
readonly output_xml_dir="$output_dir/xml-report"

# create the directory where output
if [ -n "$output_dir" ]; then
    mkdir -p "$output_dir"
fi
if [ -n "$stdout_dir" ]; then
    mkdir "$stdout_dir"
fi
if [ -n "$output_report_dir" ]; then
    mkdir "$output_report_dir"
fi
if [ -n "$output_xml_dir" ]; then
    mkdir "$output_xml_dir"
fi

# Get sub-projects list
echo_info "Loading project list"
./gradlew projectlist --init-script "$INIT_GRADLE" "-Ptestcollector.prjoutput=$tmp_project_list_path" < /dev/null > /dev/null
sort "$tmp_project_list_path" -o "$tmp_project_list_path"

# get task list
echo_info "Loading task list"
./gradlew tasks --all < /dev/null | awk -F ' ' '{print $1}' >> "$tmp_tasks_path"

# Disable UP-TO-DATE
if [ "$run_only_updated_flg" -ne 0 ] && [ "$skip_tests_flg" -ne 0 ]; then
    echo_info "Deleting the cache of test result"
    ./gradlew cleanTest < /dev/null >> /dev/null
fi

# Read each build.gradle and run each test.
if [ "$skip_tests_flg" -eq 0 ]; then
    echo_info "The tests are skipped"
else
    while read -r project_row; do
        project_name=$(awk '{print $1}' <<< "$project_row")
        if [ "$project_name" == ":" ]; then
            project_name=""
        fi
        project_dir=$(awk '{print $2}' <<< "$project_row")
        task_name="${project_name}:test"

        # Even if the build.gradle file exists, 
        # ignore it if the test task of this module does not exists
        if ! task_exists "$project_name:test" "$tmp_tasks_path"; then
            if [ -z "$project_name" ]; then
                echo_info "'$task_name' is skipped; the root project doesn't have a task 'test'."
            else
                echo_info "'$task_name' is skipped; the project '$project_name' doesn't have a task 'test'."
            fi
            continue
        fi

        # Decide filepath where output.
        output_file="$stdout_dir/$(stdout_filename "$project_name")"

        echo_info "Running test '$task_name'" 
        set +e
        # To solve the below problem, specify the redirect /dev/null to stdin:
        # https://ja.stackoverflow.com/questions/30942/シェルスクリプト内でgradleを呼ぶとそれ以降の処理がなされない
        ./gradlew --no-build-cache "$task_name" < /dev/null &> "$output_file"
        set -e
    done < "$tmp_project_list_path"
fi

# Read each build.gradle and copy test reports.
echo_info "Collecting the test results" 
while read -r project_row; do
    project_name=$(awk '{print $1}' <<< "$project_row")
    if [ "$project_name" == ":" ]; then
        project_name=""
    fi
    project_dir=$(awk '{print $2}' <<< "$project_row")
    project_name_esc=${project_name//:/__}
    stdout_file="$stdout_dir/$(stdout_filename "$project_name")"
    test_result_xml_dir="$project_dir/build/test-results/test"
    test_result_html_dir="$project_dir/build/reports/tests/test"
    test_result_xml_tar="$output_xml_dir/${project_name_esc:-"root"}.tgz"
    test_result_html_dist_dir="$output_report_dir/${project_name_esc:-"root"}"
    go_mod_path="$project_dir/go.mod"


    if ! task_exists "$project_name:test" "$tmp_tasks_path"
    then
        echo "${project_name:-"root"}" NO-TASK null NO-TASK >> "$tmp_summary_path"
        continue
    fi

    # get the result of ./gradlew test
    if [ "$skip_tests_flg" -ne 0 ]; then
        build_status=$(build_status "$stdout_file")
        task_status=$(task_status "$project_name:test" "$stdout_file")
        if [ -z "$task_status" ]; then
            task_status="null"
        fi
    else
        build_status="SKIPPED"
        task_status="null"
    fi

    if [ ! -e "$test_result_xml_dir" ]; then
        if [ -e "$go_mod_path" ]; then
            echo "${project_name:-"root"}" "$build_status" "$task_status" GO >> "$tmp_summary_path"
        elif [ "$project_name" == ":testing:integration-tests" ]; then
            echo "${project_name:-"root"}" "$build_status" "$task_status" INTEGRATION-TEST >> "$tmp_summary_path"
        else
            echo "${project_name:-"root"}" "$build_status" "$task_status" NO-RESULT >> "$tmp_summary_path"
        fi
    else
        # Count tests and print it
        row_data=$(find "$test_result_xml_dir" -name '*.xml' -print0 | xargs -0r "$PRINT_LINE_PY")
        if [ -z "$row_data" ]; then
            row_data="NO-RESULT"
        fi
        echo "${project_name:-"root"}" "$build_status" "$task_status" "$row_data" >> "$tmp_summary_path"

        # Collect the XML test report
        (
            cd "$test_result_xml_dir" &&
            find . -name '*.xml' -print0 | xargs -0r tar -czf "$test_result_xml_tar"
        )

        # Collect the HTML test report
        cp -irp "$test_result_html_dir" "$test_result_html_dist_dir"
    fi
done < "$tmp_project_list_path"

# Output the summary file
sort "$tmp_summary_path" -o "$tmp_summary_path"
cp "$tmp_summary_path" "$summary_path"

# Output index page of HTML reports
"$CREATE_REPORT_INDEX" "$tmp_summary_path" "$output_report_dir"