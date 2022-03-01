#!/usr/bin/env python3

from collections import namedtuple
import sys
from typing import Sequence
from xml.etree import ElementTree


Args = namedtuple('Args', ['test_xml_list'])


class TestSummary:
    tests: int
    passed: int
    failures: int
    errors: int
    skipped: int

    def __init__(self, tests: int, failures: int, errors: int, skipped: int):
        self.tests = tests
        self.passed = tests - failures - errors - skipped
        self.failures = failures
        self.errors = errors
        self.skipped = skipped
    
    def __add__(self, other) -> 'TestSummary':
        if not isinstance(other, TestSummary):
            return NotImplemented
        
        return TestSummary(
            self.tests + other.tests,
            self.failures + other.failures,
            self.errors + other.errors,
            self.skipped + other.skipped,
        )
    
    def result(self) -> str:
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
    def zero(cls) -> 'TestSummary':
        return TestSummary(0, 0, 0, 0)


def analyze_arguments(args: Sequence[str]) -> Args:
    if len(args) < 2:
        raise Exception(f"Illegal arguments: {args}")
    
    test_xml_list = args[1:]

    return Args(test_xml_list=test_xml_list)


def load_summary(xml_path: str) -> TestSummary:
    xml_tree = ElementTree.parse(xml_path)

    testsuite = xml_tree.getroot()
    if testsuite is None:
        testsuite = xml_tree.getroot().find('testsuite')
    if testsuite is None:
        raise Exception(f"<testsuite> is not found in the xml: {args}")

    tests = int(testsuite.attrib['tests'])
    skipped = int(testsuite.attrib['skipped'])
    failures = int(testsuite.attrib['failures'])
    errors = int(testsuite.attrib['errors'])

    summary = TestSummary(tests, failures, errors, skipped)
    return summary


if __name__ == '__main__':
    args = analyze_arguments(sys.argv)

    summary = sum(map(load_summary, args.test_xml_list), start=TestSummary.zero())

    print(summary.result(), summary.passed, summary.failures, summary.errors, summary.skipped)
