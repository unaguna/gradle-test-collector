# Gradle Test Collector

**gradle-test-collector** runs the Gradle project tests for each module and collect the results.


## Editor (vscode)

This project has been developed using visual studio code and is configured for vscode.

### Extensions

- [ShellCheck](https://marketplace.visualstudio.com/items?itemName=timonwong.shellcheck)
- [Python](https://marketplace.visualstudio.com/items?itemName=ms-python.python)
- [Code Spell Checker](https://marketplace.visualstudio.com/items?itemName=streetsidesoftware.code-spell-checker)

## Python

This project uses python in some parts. Although python has many variations of interpreter and linter, this project specifies the following:

- Use **Python3.9**
- Require packages written in [requirements.txt](requirements.txt)
  - You can install the required packages into the current python environment with the following command: `pip install -r requirements.txt`
- Format code by **[Black](https://black.readthedocs.io/en/stable/)**
  - If you use vscode, auto-formatting will runs. Otherwise, write code that conforms to Block in some way.

## Test

In this project, [shellspec](https://github.com/shellspec/shellspec) is used for testing.
Install the version of shellspec used in [the GitHub Action](.github/workflows/check.yml) on the development terminal and run the test using the following command:

```shell
shellspec
```

## Release

The release should be a single compressed archive. You get it with the following command.

```shell
./build.sh
```

Compressed files are stored in `./build/release`.

### Before release

Prior to release, please check the following. If modifications are necessary, create the branch `release` from `develop` and work on it.

- **version number**: The version number should be written in `./.version`.
- **README.md**: `./README.md` is a user' s manual. The description must match the current version.
- **Pull Request**: Releases should be made from the main branch. The release branch must be merged into the develop branch and the develop branch into the main branch. Both will be merged by pull request, using Github Action to verify that they work without abnormal termination.
