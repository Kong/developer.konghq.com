---
title: inso lint
auto_generated: true
layout: reference
content_type: reference
---

## Command Description

Lint a yaml file in the workingDir or the provided file path (with  .spectral.yml) or a spec in an Insomnia database directory

## Syntax

`inso lint [options] [command]`

## Global Flags

* `-v, --version`: output the version number
* `-w, --workingDir <dir>`: set working directory/file: .insomnia folder, *.db.json, export.yaml
* `--verbose`: show additional logs while running the command
* `--ci`: run in CI, disables all prompts, defaults to false
* `--config <path>`: path to configuration file containing above options (.insorc)
* `--printOptions`: print the loaded options

## inso lint Commands

* [inso lint spec](/inso-cli/reference/lint_spec/): Lint an API Specification, identifier can be an API Spec id or a file path
