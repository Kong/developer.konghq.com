# automated-tests

We want to ensure that our docs are functional and remain accurate. We verify that our how-tos can be followed from top to bottom by executing the instructions on the page.

## Prereqs

To generate the instruction files, the dev site must be running locally.

## How it works

The process consists of two stages:

1. Generating instruction files from the pages.
2. Running the instruction files.

There's a config file `config/tests.yaml` with some basic configuration for the tests, i.e.

* `instructionsDir`: The path to where the instruction files are located.
* `baseUrl`: The base URL of the dev site.

### Generating instructions files

The script will iterate over the list of `how-tos`, check if it needs to generate instruction files for that file, by testing the following conditions:

* The frontmatter doesn't include `automated_tests: false`.
* The file's content doesn't include `@todo`
* `gateway` is set as `products` in the frontmatter (for now, we'll add support for more products in the future).

Next, it spins up a headless browser and visits the corresponding URL for each `how-to`. For every page, it extracts instructions from data-attributes on the page. These can be about the test's setup or the steps to run:

* **Setup**: pulls the value of all the elements with the `data-test-setup` attribute. The value can be:
  * `konnect`
  * A json indicating the product and the `min_version`, i.e. `{ gateway: '3.9' }`. This and `konnect` are mutually exclusive.
* **Steps**: pulls the value of all the elements with the `data-test-step` attribute. These represent both the steps the test needs to execute and `validations` that act as the assertions.
  * `data-test-step='block'`: indicates that the extractor can copy the associated code snippet and paste it in the instructions file as a bash command.
  * `data-test-step=json`: When the value is a json object, it represents the configuration of a `validation` step, which the test will treat as an assertion.

After extracting the information, it enerates an instruction file `<url-to-file-path>/gateway.yaml` for on-prem and `<url-to-file-path>/konnect.yml` for konnect (if the page supports it) and stores them in `instructionsDir`.

### How to run it

From the root of the repo run:

1. `cd tools/automated-tests`
1. `npm ci` - installs dependencies
1. `npm run generate-instruction-files`

By default, it will iterate over all the how-tos, but it also supports generating instruction files for a subset of how-tos by passing their urls, i.e.

`npm run generate-instruction-files -- --urls='http://localhost:8888/how-to/x/' --urls='http://localhost:8888/how-to/y/'`

or by passing the corresponding files, i.e.

`npm run generate-instruction-files -- --files='../../app/_how-tos/x.md' --files='../../app/_how-tos/y.md'`.

### Running the tests

1. First, it groups the tests by runtime based on the `basename` of the instruction file, e.g. `gateway.yaml`, `konnect.yaml`.
1. Runs a docker image named after the product with all the necessary tools, which can be found in `tools/automated-test/docker/Dockerfile` (temporary until we host them somewhere).
1. Sets up the environment by running in the container the commands defined in `tools/automated-tests/config/runtimes.yaml` under the corresponding key. It also sets the `ENV` variables defined there in the container. For runtimes that have versions, it will set the corresponding env variables defined under `versions` of the entry matching `<RUNTIME>_VERSION`.
 E.g. for gateway, when running the tests with `GATEWAY_VERSION='3.9'` it will set the env variables defined in `gateway.versions` for the entry `version: '3.9'`.
1. Tests can be scoped to a specific product by setting the `PRODUCTS` env variable, e.g. `PRODUCTS=gateway`.
1. Runs the `setup` commands defined in `runtimes.yaml` once, and after each test it resets it by running the commands under `reset`.
1. For each instruction file (test), it runs its `prereqs` block.
1. Then, it runs the steps secuentially. In the case of `gateway`, steps that are strings are executed as bash commands. Validation steps (defined as json objects), are treated as assertions. They run custom code based on the step's configuration and fail/success depending on the expectation. The validation functions are defined in `tools/automated-tests/instructions/validations.js`.
1. After all the tests for a particular runtime are run, the commands defined in `cleanup` and removes the corresponding container.

#### Expected failures

There are things we can't test at the moment, like third-party integrations, webhooks, etc. However, that doesn't mean we can't test whether the gateway is set up correctly. The `config/expected_failures.yaml` file allows you to mark specific tests as expected to fail, providing the expected error message.
Expected failures do not fail the build.

### How to run them

Make sure you export your kong license as an env variable, i.e. `export KONG_LICENSE_DATA=...`

From the root of the repo run:

1. `cd tools/automated-tests`
1. `npm ci` - installs dependencies
1. `GATEWAY_VERSION='3.9' RUNTIME='gateway' PRODUCTS='gateway' npm run run-tests`

By default, it will run all the instruction files, but it also supports running specific tests, i.e.

`GATEWAY_VERSION='3.9' npm run run-tests -- --files='<path-to-instruction-file1>' --files='<path-to-instruction-file2>'`

#### Run unreleased gateway version

`GATEWAY_VERSION='3.12' PRODUCTS=gateway RUNTIME=konnect KONG_IMAGE_TAG=nightly KONG_IMAGE_NAME=kong/kong-gateway-dev npm run run-tests`

#### Supported Env variables

| Variable | Description | Required | Default Value |
|----------|-------------|----------|---------------|
| `GATEWAY_VERSION` | Specifies which gateway version to run the test agains. | true | null |
| `RUNTIME` | Specifies which runtimes (konnect/gateway) to run, runs all tests by default. | true | null |
| `PRODUCTS` | Specifies which tests to run. | true | null |
| `CONTINUE_ON_ERROR` | Whether to continue running tests after a test fails. | false | null |
