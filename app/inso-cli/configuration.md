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