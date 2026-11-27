---
title: script
---

## Command Description

Run scripts defined in .insorc

## Syntax

`script [options] <script-name>`

## Global Flags

- `-v, --version`: output the version number
- `-w, --workingDir <dir>`: set working directory/file: .insomnia folder, *.db.json, export.yaml
- `--encryption-key <key>`: key that decrypts the sensitive fields in the Insomnia data directory: the base64 text from "Copy Key" or the JWK JSON from "Export Key". A command line argument stays in the shell history, so prefer the INSOMNIA_ENCRYPTION_KEY environment variable
- `--verbose`: show additional logs while running the command
- `--ci`: run in CI, disables all prompts, defaults to false
- `--config <path>`: path to configuration file containing above options (.insorc)
- `--printOptions`: print the loaded options

