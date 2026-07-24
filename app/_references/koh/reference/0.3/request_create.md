---
title: request create
---

## Command Description

Create a new request

## Syntax

`request create [options]`

## Local Flags

- `--collection <id|name>`: Collection to create the request in
- `--parent <id>`: Parent ID (collection or folder)
- `--name <name>`: Request name
- `--method <method>`: HTTP method (default: GET)
- `--url <url>`: Request URL
- `--description <desc>`: Request description
- `-H, --header <header...>`: Headers (format: "Name: Value")
- `-p, --param <param...>`: Query params (format: "name=value")
- `--body <body>`: Request body
- `--mime <type>`: Body MIME type (default: application/json)
- `--auth <auth>`: Auth (none, bearer:token, basic:user:pass, digest:user:pass, apikey:key:value:addTo, oauth2:key=value;...)

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

