---
title: Inso CLI
auto_generated: true
content_type: reference
layout: reference
products:
    - insomnia
tools:
    - inso-cli
---


## Global Flags

* `-v, --version`: output the version number
* `-w, --workingDir <dir>`: set working directory/file: .insomnia folder, *.db.json, export.yaml
* `--verbose`: show additional logs while running the command
* `--ci`: run in CI, disables all prompts, defaults to false
* `--config <path>`: path to configuration file containing above options (.insorc)
* `--printOptions`: print the loaded options

## Commands

* [inso run](/inso-cli/reference/run/): Execution utilities
* [inso lint](/inso-cli/reference/lint/): Lint a yaml file in the workingDir or the provided file path (with  .spectral.yml) or a spec in an Insomnia database directory
* [inso export](/inso-cli/reference/export/): Export data from insomnia models
* [inso script](/inso-cli/reference/script/): Run scripts defined in .insorc

## inso run Commands

* [inso run test](/inso-cli/reference/run_test/): Run Insomnia unit test suites, identifier can be a test suite id or a API Spec id
* [inso run collection](/inso-cli/reference/run_collection/): Run Insomnia request collection, identifier can be a workspace id

## inso lint Commands

* [inso lint spec](/inso-cli/reference/lint_spec/): Lint an API Specification, identifier can be an API Spec id or a file path

## inso export Commands

* [inso export spec](/inso-cli/reference/export_spec/): Export an API Specification to a file, identifier can be an API Spec id
