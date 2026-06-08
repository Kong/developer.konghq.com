---
title: lint spec
---

## Command Description

Lint an API Specification, identifier can be an API Spec id or a file path

## Syntax

`lint spec [options] [identifier]`

## Local Flags

- `-r, --ruleset <path>`: path to a Spectral ruleset file, overrides default OAS ruleset and any ruleset in the API Spec folder

## Global Flags

- `-v, --version`: output the version number
- `-w, --workingDir <dir>`: set working directory/file: .insomnia folder, *.db.json, export.yaml
- `--verbose`: show additional logs while running the command
- `--ci`: run in CI, disables all prompts, defaults to false
- `--config <path>`: path to configuration file containing above options (.insorc)
- `--printOptions`: print the loaded options

