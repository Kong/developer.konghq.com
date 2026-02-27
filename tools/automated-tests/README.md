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

### Config: `runtimes.yaml`

The `config/runtimes.yaml` file defines the runtime configurations grouped by **deployment model** and **product**.

The top-level keys are deployment models (`on-prem`, `konnect`). Under each deployment model, products are listed (e.g. `gateway`, `ai-gateway`, `operator`, `event-gateway`).

Each product can define:

* `versions`: A list of supported versions with version-specific env variables (e.g. `KONG_IMAGE_NAME`, `KONG_IMAGE_TAG`).
* `env`: Environment variables shared across all versions.
* `setup`: Commands to run when setting up the product. May include sub-keys like `rbac` and `wasm` for alternative setup modes.
* `cleanup`: Commands to run after all tests for this product are done.
* `reset`: Commands to run between each test to reset the environment.

Example structure:

```yaml
on-prem:
  gateway:
    versions: ...
    env: ...
    setup: ...
    cleanup: ...
    reset: ...
  ai-gateway:
    versions: ...
    env: ...
    setup: ...
    cleanup: ...
    reset: ...
  operator:
    setup: ...
    cleanup: ...
    reset: ...

konnect:
  gateway:
    setup: ...
    cleanup: ...
    reset: ...
  event-gateway:
    setup: ...
    cleanup: ...
    reset: ...
```

### Generating instructions files

The script will iterate over the list of `how-tos`, check if it needs to generate instruction files for that file, by testing the following conditions:

* The frontmatter doesn't include `automated_tests: false`.
* The file's content doesn't include `@todo`
* One of `gateway`, `ai-gateway`, `event-gateway`, or `operator` is set as `products` in the frontmatter.

Next, it spins up a headless browser and visits the corresponding URL for each `how-to`. For every page, it extracts instructions from data-attributes on the page. These can be about the test's setup or the steps to run:

* **Setup**: pulls the value of all the elements with the `data-test-setup` attribute. The value can be:
  * `konnect`
  * `operator`
  * A json indicating the product and the `min_version`, i.e. `{ gateway: '3.9' }`. This and `konnect` are mutually exclusive.
* **Steps**: pulls the value of all the elements with the `data-test-step` attribute. These represent both the steps the test needs to execute and `validations` that act as the assertions.
  * `data-test-step='block'`: indicates that the extractor can copy the associated code snippet and paste it in the instructions file as a bash command.
  * `data-test-step=json`: When the value is a json object, it represents the configuration of a `validation` step, which the test will treat as an assertion.

After extracting the information, it generates an instruction file at `<url-path>/<deployment-model>/<product>.yaml` (e.g. `how-to/my-guide/on-prem/gateway.yaml`, `how-to/my-guide/konnect/gateway.yaml`) and stores them in `instructionsDir`.

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

1. First, it groups the tests by **deployment model** (from the parent directory name, e.g. `on-prem`, `konnect`) and **product** (from the instruction file basename, e.g. `gateway.yaml`, `operator.yaml`).
1. Runs a docker image with all the necessary tools, which can be found in `tools/automated-test/docker/Dockerfile` (temporary until we host them somewhere).
1. Sets up the environment by running in the container the commands defined in `tools/automated-tests/config/runtimes.yaml` under the corresponding `<deployment-model>.<product>` key. It also sets the `ENV` variables defined there in the container. For products that have versions, it will set the corresponding env variables defined under `versions` of the entry matching `GATEWAY_VERSION`.
 E.g. for on-prem gateway, when running the tests with `GATEWAY_VERSION='3.9'` it will set the env variables defined in `on-prem.gateway.versions` for the entry `version: '3.9'`.
1. Tests can be scoped to a specific product by setting the `PRODUCTS` env variable, e.g. `PRODUCTS=gateway`.
1. Tests can be scoped to a specific deployment model by setting the `DEPLOYMENT_MODEL` env variable, e.g. `DEPLOYMENT_MODEL=on-prem`.
1. Runs the `setup` commands defined in `runtimes.yaml` once, and after each test it resets it by running the commands under `reset`.
1. For each instruction file (test), it runs its `prereqs` block.
1. Then, it runs the steps sequentially. Steps that are strings are executed as bash commands. Validation steps (defined as json objects), are treated as assertions. They run custom code based on the step's configuration and fail/success depending on the expectation. The validation functions are defined in `tools/automated-tests/instructions/validations.js`.
1. After all the tests for a particular deployment model + product are run, the commands defined in `cleanup` are executed and the corresponding container is removed.

#### Expected failures

There are things we can't test at the moment, like third-party integrations, webhooks, etc. However, that doesn't mean we can't test whether the gateway is set up correctly. The `config/expected_failures.yaml` file allows you to mark specific tests as expected to fail, providing the expected error message.
Expected failures do not fail the build.

### How to run them

Make sure you export your kong license as an env variable, i.e. `export KONG_LICENSE_DATA=...`

From the root of the repo run:

1. `cd tools/automated-tests`
1. `npm ci` - installs dependencies
1. `GATEWAY_VERSION='3.9' DEPLOYMENT_MODEL='on-prem' PRODUCTS='gateway' npm run run-tests`

By default, it will run all the instruction files, but it also supports running specific tests, i.e.

`GATEWAY_VERSION='3.9' npm run run-tests -- --files='<path-to-instruction-file1>' --files='<path-to-instruction-file2>'`

#### Run on-prem operator tests

`DEPLOYMENT_MODEL='on-prem' PRODUCTS='operator' npm run run-tests`

#### Run unreleased gateway version

`GATEWAY_VERSION='3.12' PRODUCTS=gateway DEPLOYMENT_MODEL=on-prem KONG_IMAGE_TAG=nightly KONG_IMAGE_NAME=kong/kong-gateway-dev npm run run-tests`

#### Run konnect event-gateway tests

`DEPLOYMENT_MODEL='konnect' PRODUCTS='event-gateway' npm run run-tests`

#### Supported Env variables

| Variable | Description | Required | Default Value |
|----------|-------------|----------|---------------|
| `GATEWAY_VERSION` | Specifies which gateway version to run the tests against. Required for products with a version matrix. | conditional | null |
| `DEPLOYMENT_MODEL` | Specifies which deployment model (`on-prem`/`konnect`) to run, runs all by default. | false | null |
| `PRODUCTS` | Specifies which products to test (e.g. `gateway`, `ai-gateway`, `operator`, `event-gateway`). | true | null |
| `CONTINUE_ON_ERROR` | Whether to continue running tests after a test fails. | false | null |
