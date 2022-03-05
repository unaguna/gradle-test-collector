#!/usr/bin/env bash

################################################################################
# Error handling
################################################################################

set -eu
set -o pipefail

# Disable overwriting of files.
# The effect of the option is that projects which have already output the dependence tree will be skipped.
# (However, even if the previous output is empty or wrong, it will be skipped.)
# If you want to get the trees that has already been output before again, comment out it.
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


################################################################################
# Include
################################################################################

# shellcheck source=libs/ana-gradle.sh
source "$SCRIPT_DIR/libs/ana-gradle.sh"


################################################################################
# Functions
################################################################################

# Output an information
#
# Because stdout is used as output of gradlew in this script,
# any messages should be output to stderr.
function echo_info () {
    echo "$SCRIPT_NAME: " "$@" >&2
}

# Output an error
#
# Because stdout is used as output of gradlew in this script,
# any messages should be output to stderr.
function echo_err() {
    echo "$SCRIPT_NAME: " "$@" >&2
}

# Output an usage
function echo_usage() {
    echo "Usage: $SCRIPT_NAME -d <output_dir> <main-project-path>" 1>&2
}


################################################################################
# Constant values
################################################################################

readonly PRINT_LINE_PY="$SCRIPT_DIR/get-summary.py"

readonly CREATE_REPORT_INDEX="$SCRIPT_DIR/create-report-index.py"

readonly REPORT_INDEX_TEMPLATE="$SCRIPT_DIR/report_index_template.html"


################################################################################
# Analyze arguments
################################################################################

args=( )
while [ $# -gt 0 ]
do
    case $1 in
        -d)
            output_dir=$2
            shift
            ;;
        *)
            args+=( "$1" )
            ;;
    esac
    shift
done

if [ ${#args[@]} -ne 1 ]; then
    echo_usage
    exit 1
fi

# The directory path of the main project build.gradle
readonly main_project_dir="${args[0]}"

# Make output_dir absolute path in order to not depend on the current directory
# (Assume that the current directory will change.)
# If it is not specified, it keeps empty.
if [ -n "${output_dir:-""}" ]
then
    output_dir=$(cd "$ORIGINAL_PWD"; cd "$(dirname "$output_dir")"; pwd)"/"$(basename "$output_dir")
    readonly output_dir
else
    echo_usage
    exit 1
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

readonly summary_path="$output_dir/summary.txt"
readonly output_report_dir="$output_dir/test-report"
readonly output_xml_dir="$output_dir/xml-report"

# Create the directory where output
if [ -n "$output_dir" ]; then
    mkdir -p "$output_dir"
fi
if [ -n "$output_report_dir" ]; then
    mkdir "$output_report_dir"
fi
if [ -n "$output_xml_dir" ]; then
    mkdir "$output_xml_dir"
fi


# Get sub-projects list
./gradlew projects < /dev/null >> "$tmp_project_list_path"

# get task list
./gradlew tasks --all < /dev/null | awk -F ' ' '{print $1}' >> "$tmp_tasks_path"


# Read each build.gradle and output dependencies tree of it.
find . -type f -name 'build.gradle*' -print | while read -r project_file; do
    project_dir=$(dirname "$project_file")
    project_name=$(sed -e "s|/|:|g" -e "s|^\.||" <<< "$project_dir")
    project_name_esc=${project_name//:/__}
    test_result_xml_dir="$project_dir/build/test-results/test"
    test_result_html_dir="$project_dir/build/reports/tests/test"
    test_result_xml_tar="$output_xml_dir/${project_name_esc:-"root"}.tgz"
    test_result_html_dist_dir="$output_report_dir/${project_name_esc:-"root"}"
    go_mod_path="$project_dir/go.mod"

    # Even if the build.gradle file exists, 
    # ignore it if it is not recognized as a sub project by the root project.
    if ! is_sub_project "$project_name" "$tmp_project_list_path"; then
        continue
    fi

    if ! task_exists "$project_name:test" "$tmp_tasks_path"
    then
        echo "${project_name:-"root"}" NO-TASK >> "$tmp_summary_path"
    elif [ ! -e "$test_result_xml_dir" ]; then
        if [ -e "$go_mod_path" ]; then
            echo "${project_name:-"root"}" GO >> "$tmp_summary_path"
        elif [ "$project_name" == ":testing:integration-tests" ]; then
            echo "${project_name:-"root"}" INTEGRATION-TEST >> "$tmp_summary_path"
        else
            echo "${project_name:-"root"}" NO-TESTS >> "$tmp_summary_path"
        fi
    else
        # Count tests and print it
        row_data=$(find "$test_result_xml_dir" -name '*.xml' -print0 | xargs -0 "$PRINT_LINE_PY")
        echo "${project_name:-"root"}" "$row_data" >> "$tmp_summary_path"

        # Collect the XML test report
        (
            cd "$test_result_xml_dir" &&
            find . -name '*.xml' -print0 | xargs -0 tar -czf "$test_result_xml_tar"
        )

        # Collect the HTML test report
        cp -irp "$test_result_html_dir" "$test_result_html_dist_dir"
    fi
done

# Output the summary file
sort "$tmp_summary_path" -o "$tmp_summary_path"
cp "$tmp_summary_path" "$summary_path"

# Output index page of HTML reports
"$CREATE_REPORT_INDEX" --template "$REPORT_INDEX_TEMPLATE" "$tmp_summary_path" "$output_report_dir"
