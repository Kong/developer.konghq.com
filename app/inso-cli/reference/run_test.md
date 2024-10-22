---
title: inso run test
auto_generated: true
layout: reference
content_type: reference
---

## Command Description

Run Insomnia unit test suites, identifier can be a test suite id or a API Spec id

## Syntax

`inso run test [options] [identifier]`

## Local Flags

* `-e, --env <identifier>`: environment to use
* `-t, --testNamePattern <regex>`: run tests that match the regex
* `-r, --reporter <reporter>`: reporter to use, options are [dot, list, min, progress, spec, tap]
* `-b, --bail`: abort ("bail") after first test failure
* `--keepFile`: do not delete the generated test file
* `-k, --disableCertValidation`: disable certificate validation for requests with SSL

## Global Flags

* `-v, --version`: output the version number
* `-w, --workingDir <dir>`: set working directory/file: .insomnia folder, *.db.json, export.yaml
* `--verbose`: show additional logs while running the command
* `--ci`: run in CI, disables all prompts, defaults to false
* `--config <path>`: path to configuration file containing above options (.insorc)
* `--printOptions`: print the loaded options
