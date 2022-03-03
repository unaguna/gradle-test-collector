#!/usr/bin/env bash


# Check if the specified string is a name of sub-project
#
# Arguments
#   $1: a string
#   $2: the path of output of `gradle projects`
#
# Returns
#   Returns 0 if the specified string is a name of sub-project.
#   Returns 1 otherwise.
function is_sub_project () {
    local -r sub_project_name=$1
    local -r project_list_path=$2

    set +e
    grep -e "Project '$sub_project_name'$" "$project_list_path" &> /dev/null
    result=$?
    set -e

    if [ $result -ne 0 ] && [ $result -ne 1 ]; then
        echo_err "Failed to reference the temporary file created: $project_list_path"
        exit $result
    fi

    return $result
}

# Check task existence
#
# Arguments
#   $1 - A task name. It can start with ':', such as ":sub-project:test". 
#   $2 - the path of output of `gradle tasks`
#
# Returns
#   Returns 0 if specified task exists. Returns 1 otherwise.
function task_exists() {
    local -r task_name=${1#:}
    local -r task_list_path=$2

    set +e
    grep -e "^$task_name$" "$task_list_path" &> /dev/null
    result=$?
    set -e

    if [ $result -ne 0 ] && [ $result -ne 1 ]; then
        echo_err "Failed to reference the temporary file created: $task_list_path"
        exit $result
    fi

    return $result
}