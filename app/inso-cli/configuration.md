---
title: Inso CLI configuration

description: Inso CLI can be configured with a configuration file, allowing you to specify options and scripts.

content_type: reference
layout: reference

products:
  - insomnia

tools:
  - inso-cli

breadcrumbs:
  - /inso-cli/

related_resources:
  - text: Inso CLI
    url: /inso-cli/
  - text: Continuous Integration with Inso CLI
    url: /inso-cli/continuous-integration/
---

Inso CLI can be configured with a configuration file, allowing you to specify options and scripts. For example, when running in a CI environment, you may choose to specify the steps as scripts in a configuration file, so that the same commands can be run both locally and in CI.

Inso CLI uses [cosmiconfig](https://github.com/davidtheclark/cosmiconfig) for configuration file management. This automatically uses any of the following items from the working tree:

* `inso` property in `package.json`
* `.insorc` file in JSON or YAML format
* `.insorc.json` file
* `.insorc.yaml`, `.insorc.yml`, or `.insorc.js` file
* `inso.configuration.js` file exporting a JS object

You can also use the `--configuration $FILE` global option to specify the file to use.

## Inso CLI options

The `options` field in the configuration file can be used to define [global options](/inso-cli/reference/#global-flags). You can use any of the global flags in this field. Flags without arguments should be configured as booleans in the configuration file. For example, you can use the following configuration to show additional logs when running all commands:

```yaml
options:
  verbose: true
```

Any options specified in this file will apply to all scripts and manual commands. You can override these options by specifying them explicitly when invoking a script or command. The priority order works as follows:
1. Command options
1. Configuration file options
1. Default options

## Request timeout

Use the request-timeout option to control how long Inso CLI waits before failing a network request during collection and test execution:

### Command line

Set the timeout for an individual command:

```bash
inso run collection wrk_123 --request-timeout 30000
```

### Configuration file

Inso CLI loads configuration from several supported files. The most common is the `.insorc` file. Set a default timeout for all Inso CLI commands by adding the timeout option to your `.insorc` file.

Configuration keys in `.insorc` follow a simple rule:  
start with the flag name, remove `--`, then convert kebab-case to camelCase.

For the `--request-timeout` flag, the configuration key becomes `requestTimeout`:

```yaml
# .insorc.yaml
options:
  requestTimeout: 30000
```

## Inso CLI scripts

Scripts in the Inso CLI configuration file can have any name and can be nested. Scripts must be prefixed with `inso`.

## Inso CLI configuration example

The following example shows how you can format your Inso CLI configuration file with options and scripts:

```yaml
# .insorc.yaml

options:
  ci: false
scripts:
  test-spec: inso run test Demo --env DemoEnv --reporter progress
  test-spec:200s: inso testSpec --testNamePattern 200
  test-spec:404s: inso testSpec --testNamePattern 404

  test-math-suites: inso run test uts_8783c30a24b24e9a851d96cce48bd1f2 --env DemoEnv 
  test-request-suite: inso run test uts_bce4af --env DemoEnv --bail

  lint: inso lint spec Demo # must be invoked as `inso script lint`
```

## Request timeout setting

Insomnia Desktop v12.1.0 adds a **Request timeout (ms)** preference that controls how long the application waits for network operations.

The Inso CLI does not currently support configuring a request timeout through CLI flags or the `options` section in `.insorc`.

This page will be updated when request-timeout support is added to the CLI in a future release. For details on the Desktop preference, see the Insomnia application documentation.
