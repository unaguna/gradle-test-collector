# Gradle Test Collector

**gradle-test-collector** runs the Gradle project tests for each module and collect the results.


## Execution Environment

- It runs with bash (Not sure if it works with other shells.)
- It requires python >=3.9
    To verify it, run `python3 --version` and check it's version.


## Usage Example (Run the tests and get the summary)

1. Clone this repository

1. Run the script `run-each-test.sh`

    ```shell
    ./run-each-test.sh -d result --rerun-tests ~/gradle-project
    ```

    Each argument in the above example is treated as follows:
    - **-d** result -- Directory where the results will be output. You can also specify an absolute path.
    - **--rerun-tests** -- If it is specified, tests that have already been run are also rerun.
    - **~/gradle-project** -- The root directory of the gradle project.

1. Check the results

    You can view result by a web browser; in the example above, the result will be `result/test-report/index.html`.

    Also, reports in xml format will be archived; in the example above, the result will be `result/xml-report/*.tgz`.


## Usage Example (to collect the results of a test that has already been run)

1. Clone this repository

1. Run the script `test-summary.sh`

    ```shell
    ./test-summary.sh -d result ~/gradle-project
    ```

    The argument means the same as in [`run-each-test.sh`](#usage-example-run-the-tests-and-get-the-summary) above.

1. Check the results

    Same as in "[Usage Example (Run the tests and get the summary)](#usage-example-run-the-tests-and-get-the-summary)"


## For contributor of these scripts

Read [README_for_contributor.md](./README_for_contributor.md)