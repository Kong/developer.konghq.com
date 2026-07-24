---
title: request run
---

## Command Description

Run a request

## Syntax

`request run [options] <id|name>`

## Local Flags

- `--collection <id|name>`: Scope search to a specific collection
- `--url <url>`: Override request URL
- `--method <method>`: Override HTTP method
- `-H, --header <header...>`: Override headers (format: "Name: Value"); replaces all stored headers
- `-p, --param <param...>`: Override query params (format: "name=value"); replaces all stored params
- `--body <body>`: Override request body
- `--mime <type>`: Override body MIME type (used with --body)
- `--auth <auth>`: Override auth (none, bearer:token, basic:user:pass, digest:user:pass, apikey:key:value[:addTo] ,oauth2:key=value;...)
- `--body-output <mode>`: Body output mode: auto (default), or file
- `--max-body-bytes <bytes>`: Maximum inline body size for auto mode

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

