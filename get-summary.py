#!/usr/bin/env python3

"""Create a row of summary table
"""

from collections import namedtuple
import sys
from typing import Sequence
from xml.etree import ElementTree


Args = namedtuple("Args", ["test_xml_list"])


class TestSummary:
    """Test summary of tests of one sub-project."""

    #: The number of tests
    tests: int
    #: The number of tests passed
    passed: int
    #: The number of tests failed
    failures: int
    #: The number of tests errord
    errors: int
    #: The number of tests skipped
    skipped: int

    def __init__(self, tests: int, failures: int, errors: int, skipped: int):
        self.tests = tests
        self.passed = tests - failures - errors - skipped
        self.failures = failures
        self.errors = errors
        self.skipped = skipped

    def __add__(self, other) -> "TestSummary":
        if not isinstance(other, TestSummary):
            return NotImplemented

        return TestSummary(
            self.tests + other.tests,
            self.failures + other.failures,
            self.errors + other.errors,
            self.skipped + other.skipped,
        )

    def result(self) -> str:
        """Result such as 'passed' or 'failed'"""
        if self.tests <= 0:
            return "NO-TESTS"
        elif self.failures > 0:
            return "failed"
        elif self.errors > 0:
            return "failed"
        elif self.skipped > 0:
            return "ignored"
        else:
            return "passed"

    @classmethod
    def zero(cls) -> "TestSummary":
        """Zero element of TestSummary

        It is used by a start value of `sum()`.

        Returns:
            TestSummary: Zero element
        """
        return TestSummary(0, 0, 0, 0)


def analyze_arguments(args: Sequence[str]) -> Args:
    if len(args) >= 2:
        test_xml_list = args[1:]
    else:
        test_xml_list = []

    return Args(test_xml_list=test_xml_list)


def load_summary(xml_path: str) -> TestSummary:
    """Load a xml summary file wrote by Gradle

    Args:
        xml_path (str): the filepath of the xml summary file

    Returns:
        TestSummary: New instance.
    """
    xml_tree = ElementTree.parse(xml_path)

    testsuite = xml_tree.getroot()
    if testsuite is None:
        testsuite = xml_tree.getroot().find("testsuite")
    if testsuite is None:
        raise Exception(f"<testsuite> is not found in the xml: {args}")

    tests = int(testsuite.attrib["tests"])
    skipped = int(testsuite.attrib["skipped"])
    failures = int(testsuite.attrib["failures"])
    errors = int(testsuite.attrib["errors"])

    summary = TestSummary(tests, failures, errors, skipped)
    return summary


if __name__ == "__main__":
    args = analyze_arguments(sys.argv)

    summary = sum(map(load_summary, args.test_xml_list), start=TestSummary.zero())

    print(
        summary.result(),
        summary.passed,
        summary.failures,
        summary.errors,
        summary.skipped,
    )
