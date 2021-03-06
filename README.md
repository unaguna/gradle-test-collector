# Gradle Test Collector

**gradle-test-collector** runs the Gradle project tests for each module and collect the results.


## Execution Environment

- It runs with bash (Not sure if it works with other shells.)
- It requires python >=3.9. To verify it, run `python3 --version` and check it's version.
  - In addition, some packages written in [requirements.txt](requirements.txt) must be installed
    - You can install the required packages into the current python environment with the following command: `pip install -r requirements.txt`


## Usage Example

1. Download a release file `gradle-test-collector.x.x.x.tgz` from [here](https://github.com/unaguna/gradle-test-collector/releases) and extract it.

1. Run the script `collect-tests.sh`

    ```shell
    ./collect-tests.sh -d result ~/gradle-project
    ```

    Each argument in the above example is treated as follows:
    - **-d** result -- Directory where the results will be output. You can also specify an absolute path.
    - ~/gradle-project -- The root directory of the gradle project.

    If you want to know about other options, please run `./collect-tests.sh --help`

1. Check the results

    You can view result by a web browser; in the example above, the result will be `result/test-report/index.html`.

    Also, reports in xml format will be archived; in the example above, the result will be `result/xml-report/*.tgz`.


## For contributor of these scripts

Read [README_for_contributor.md](./README_for_contributor.md)