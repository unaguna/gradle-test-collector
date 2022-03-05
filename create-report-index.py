#!/usr/bin/env python3

import argparse
import chevron
import os

# The current directory when this script started.
ORIGINAL_PWD = os.getcwd()

# The directory path of this script file
SCRIPT_DIR = os.path.dirname(os.path.abspath(__file__))

# The path of this script file
SCRIPT_NAME = os.path.basename(os.path.abspath(__file__))

# The path of the template HTML file
TEMPLATE_PATH = os.path.join(SCRIPT_DIR, 'report_index_template.html')


def noneor(value, default):
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
    project_name: str
    project_name_esc: str
    result_str: str

    @classmethod
    def from_line(cls, line: str) -> 'Summary':
        line_parts = line.split()

        result = Summary()
        result.project_name = line_parts[0]
        result.project_name_esc = line_parts[0].replace(':', '__')
        result.result_str = line_parts[1]

        return result


def load_summary(summary_path: str) -> list[Summary]:
    result = []
    
    with open(summary_path, 'r') as f:
        for line in f:
            result.append(Summary.from_line(line))
    
    return result


class Args:
    """Arguments of command
    """
    template_path: str
    summary_path: str
    output_path: str

    def __init__(self):
        parser = argparse.ArgumentParser()
        parser.add_argument('--template',
                            help='',
                            default=None)
        parser.add_argument("summary_path")
        parser.add_argument("output_path")

        arguments = parser.parse_args()

        self.template_path = noneor(arguments.template,
                                    os.path.join(SCRIPT_DIR, 'report_index_template.html'))
        self.output_path = arguments.output_path
        self.summary_path = arguments.summary_path


if __name__ == '__main__':
    args = Args()

    summary_list = load_summary(args.summary_path)

    with open(args.template_path, 'r') as f:
        output_text = chevron.render(f, {'project_table': summary_list})
    
    with open(args.output_path, 'w') as f:
        print(output_text, file=f)
