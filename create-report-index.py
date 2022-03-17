#!/usr/bin/env python3

"""Create index page of test report with the template and summary data
"""

import argparse
import datetime
import chevron
import os
from typing import Optional

# The current directory when this script started.
ORIGINAL_PWD = os.getcwd()

# The directory path of this script file
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# The path of this script file
SCRIPT_NAME = os.path.basename(os.path.abspath(__file__))

# The name of this tool
TOOL_NAME = "Gradle Test Collector"

# The URL of this tool
TOOL_URL = "https://github.com/unaguna/gradle-test-collector"


def dfor(value, default):
    """null coalescing operator

    Args:
        value (Any) : value
        default (Any) : default value

    Returns:
        Any:
            If the specified value is not None, return the specified value.
            Otherwise, return the specified default value.
    """
    if value is None:
        return default
    else:
        return value


class Summary:
    """Test summary of tests of one sub-project."""

    #: The name of sub-project
    project_name: str
    #: The name of sub-project (escape a charactor ':')
    project_name_esc: str
    #: Status of this summary. It depends on build_status_str and result_str
    status_str: str
    #: Status of gradle build, such as 'SUCCESSFUL' or 'FAILED'
    build_status_str: str
    #: Result such as 'passed' or 'failed'
    result_str: str
    #: Whether this record is effective. If no tests are included, this record is not effective.
    is_effective: bool
    #: The number of tests
    tests: Optional[int]
    #: The number of tests passed
    passed: Optional[int]
    #: The number of tests failed
    failures: Optional[int]
    #: The number of tests errord
    errors: Optional[int]
    #: The number of tests skipped
    skipped: Optional[int]

    def __init__(
        self,
        project_name: str,
        build_status_str: str,
        result_str: str,
        passed: Optional[int],
        failures: Optional[int],
        errors: Optional[int],
        skipped: Optional[int],
    ) -> None:
        self.project_name = project_name
        self.build_status_str = build_status_str
        self.result_str = result_str
        self.passed = passed
        self.failures = failures
        self.errors = errors
        self.skipped = skipped

        self.project_name_esc = project_name.replace(":", "__")

        self.status_str = self.decide_status_str(self.build_status_str, self.result_str)
        self.tests = self.decide_tests(
            self.passed, self.failures, self.errors, self.skipped
        )
        self.is_effective = self.decide_is_effective(self.tests)

    @classmethod
    def decide_status_str(
        cls,
        build_status_str: str,
        result_str: str,
    ) -> str:
        """Calculate the value of the field `status_str`

        Normally, this function should be defined as a property,
        but in order to be able to refer to it from chevron,
        `status_str` is defined as a field and this function determines its value.

        Args:
            build_status_str (str): The value of `build_status_str` of the target instance.
            result_str (str): The value of `result_str` of the target instance.

        Returns:
            str: The value of `status_str`
        """
        if result_str.lower() == "failed":
            return result_str
        elif build_status_str.lower() == "failed":
            return "ERROR"
        else:
            return result_str

    @classmethod
    def decide_tests(
        cls,
        passed: Optional[int],
        failures: Optional[int],
        errors: Optional[int],
        skipped: Optional[int],
    ) -> Optional[int]:
        """Calculate the value of the field `tests`

        Normally, this function should be defined as a property,
        but in order to be able to refer to it from chevron,
        `tests` is defined as a field and this function determines its value.

        Args:
            passed (Optional[int]): The value of `passed` of the target instance.
            failures (Optional[int]): The value of `failures` of the target instance.
            errors (Optional[int]): The value of `errors` of the target instance.
            skipped (Optional[int]): The value of `skipped` of the target instance.

        Returns:
            Optional[int]: The value of `tests`
        """
        count_list = list(
            filter(lambda x: x is not None, [passed, failures, errors, skipped])
        )
        if len(count_list) > 0:
            return sum(count_list, 0)
        else:
            return None

    @classmethod
    def decide_is_effective(self, tests: Optional[int]) -> bool:
        """Calculate the value of the field `is_effective`

        Normally, this function should be defined as a property,
        but in order to be able to refer to it from chevron,
        `is_effective` is defined as a field and this function determines its value.

        Args:
            tests (Optional[int]): The value of `tests` of the target instance.

        Returns:
            bool: The value of `is_effective`
        """
        return tests is not None

    @classmethod
    def from_line(cls, line: str) -> "Summary":
        """Create instance from a line of summary table

        Args:
            line (str): A line of summary table.

        Returns:
            Summary: new instance
        """
        line_parts = line.split()

        project_name = line_parts[0]
        build_status_str = line_parts[1]
        result_str = line_parts[2]
        if len(line_parts) > 3:
            passed = int(line_parts[3])
        else:
            passed = None
        if len(line_parts) > 4:
            failures = int(line_parts[4])
        else:
            failures = None
        if len(line_parts) > 5:
            errors = int(line_parts[5])
        else:
            errors = None
        if len(line_parts) > 6:
            skipped = int(line_parts[6])
        else:
            skipped = None

        result = Summary(
            project_name=project_name,
            build_status_str=build_status_str,
            result_str=result_str,
            passed=passed,
            failures=failures,
            errors=errors,
            skipped=skipped,
        )

        return result


def load_summary(summary_path: str) -> list[Summary]:
    """Load a summary table

    Args:
        summary_path (str): the filepath of the summary table

    Returns:
        list[Summary]: New instance. Each element corresponds to a row of the table.
    """
    result = []

    with open(summary_path, "r") as f:
        for line in f:
            result.append(Summary.from_line(line))

    return result


class Args:
    """Arguments of command"""

    template_index_path: str
    template_top_path: str
    summary_path: str
    output_dir_path: str

    def __init__(self):
        parser = argparse.ArgumentParser()
        parser.add_argument("--template-index", help="", default=None)
        parser.add_argument("--template-top", help="", default=None)
        parser.add_argument("summary_path")
        parser.add_argument("output_dir_path")

        arguments = parser.parse_args()

        self.template_index_path = dfor(
            arguments.template_index,
            os.path.join(SCRIPT_DIR, "report_index_template.html"),
        )
        self.template_top_path = dfor(
            arguments.template_top,
            os.path.join(SCRIPT_DIR, "report_index_top_template.html"),
        )
        self.output_dir_path = arguments.output_dir_path
        self.summary_path = arguments.summary_path


if __name__ == "__main__":
    args = Args()

    output_index_path = os.path.join(args.output_dir_path, "index.html")
    output_top_path = os.path.join(args.output_dir_path, "top.html")

    summary_list = load_summary(args.summary_path)
    data = {
        "tool_name": TOOL_NAME,
        "tool_url": TOOL_URL,
        "datetime_str": datetime.datetime.now().strftime("%b %d, %Y, %l:%M:%S %p"),
        "project_table": summary_list,
    }

    with open(args.template_index_path, "r") as f:
        output_text = chevron.render(f, data)

    with open(output_index_path, "w") as f:
        print(output_text, file=f)

    with open(args.template_top_path, "r") as f:
        output_text = chevron.render(f, data)

    with open(output_top_path, "w") as f:
        print(output_text, file=f)
