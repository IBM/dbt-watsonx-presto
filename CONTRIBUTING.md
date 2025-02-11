# Contributing to `dbt-watsonx-presto`

We welcome contributions to `dbt-watsonx-presto`! If you'd like to help, follow the steps below to get started.

### How to contribute?

You can contribute to `dbt-watsonx-presto` by forking the repository. For a detailed overview on forking, check out the [GitHub docs on forking](https://help.github.com/en/articles/fork-a-repo). In short, you will need to:

1. Fork the `dbt-watsonx-presto` repository
2. Clone your fork locally.
3. Create a new branch for your proposed changes.
4. Push changes to your fork.
5. Open a pull request against the `IBM/dbt-watsonx-presto` repository from your fork

## Setting up an environment

There are some tools that will be helpful to you in developing locally. While this list is relevant for `dbt-watsonx-presto`, many of these tools are used commonly across open-source Python projects.

### Tools

These are the tools used in `dbt-watsonx-presto` development and testing:

- [`pytest`](https://docs.pytest.org/en/latest/) for defining, discovering, and running tests.
- [`tox`](https://tox.readthedocs.io/en/latest/) to manage virtual environments across Python versions.
- [`flake8`](https://flake8.pycqa.org/en/latest/) for code linting.
- [`black`](https://github.com/psf/black) for code formatting.
- [`isort`](https://pycqa.github.io/isort/) for sorting imports.
- [`flaky`](https://opensource.box.com/flaky/): To rerun flaky tests to improve test reliability.

Though understanding all of these tools isn't mandatory, we recommend familiarizing yourself with them to contribute more effectively.

#### Virtual environments

We strongly recommend using a Python virtual environment for development. To set up a new virtual environment, run:

```sh
python3 -m venv env
source env/bin/activate
```
This will create and activate a new virtual environment, ensuring a clean setup for your development work.

## Running `dbt-watsonx-presto` in development

### Installation

After [Setting up an environment](#setting-up-an-environment), install the project dependencies by running:

```sh
pip install --upgrade pip
```
Next, install `dbt-watsonx-presto` (and its dependencies) with:

```sh
pip install -e . -r dev_requirements.txt
```

The -e . option installs dbt-watsonx-presto in "editable" mode, meaning any changes you make to the code will be immediately reflected in your local environment.

### Running `dbt-watsonx-presto`

Once you've installed everything, ensure that the dbt command is pointing to the local source code by running:

```sh
which dbt
```

This should show the path to dbt inside your virtual environment. Additionally, ensure your profile is set up to connect to your target database. If needed, create a new profile for connecting to a local Presto or watsonx.data instance


## Testing

Testing is a crucial part of contributing. Once you've made code changes, you should run existing tests and add new ones to ensure the stability and reliability of the project.


### Initial setup

To run tests, you will need access to a Presto or watsonx.data instance. Once that's set up, you can proceed with running tests locally.


### Running Tests

You can use pytest to run tests. The following commands help you test locally:


- Run all unit tests:

```sh
# run all unit tests in a file
python3 -m pytest tests/unit/
```
- Run a specific test:

```sh
# run a specific unit test
python3 -m pytest tests/unit/test_adapter.py::TestPrestoAdapter::test_acquire_connection
```
These commands allow you to run tests directly from the command line.

### Adding Test Cases
Whenever you introduce new features or fix bugs, ensure that you add test cases to verify your changes. This includes writing appropriate unit tests for functionality and integration tests where needed. Well-tested code is critical for maintaining long-term project stability.

## adding-changelog-entry

We use [changie](https://changie.dev) to generate `CHANGELOG` entries. **Note:** Do not edit the `CHANGELOG.md` directly. Your modifications will be lost.

Follow the steps to [install `changie`](https://changie.dev/guide/installation/) for your system.

Once changie is installed and your PR is created, simply run `changie new` and changie will walk you through the process of creating a changelog entry.  Commit the file that's created and your changelog entry is complete!

You don't need to worry about which `dbt-watsonx-presto` version your change will go into. Just create the changelog entry with `changie`, and open your PR against the `main` branch.


## Submitting a Pull Request

Once your changes are complete and tested, it's time to open a pull request:

1. Push your changes to your fork.
2. Open a pull request from your fork to the IBM/dbt-watsonx-presto repository.
3. A maintainer will review your PR and may request additional changes or tests.
4. Once your PR is approved and all tests pass, it will be merged into the main branch.

That's it! Happy coding! :tada:
