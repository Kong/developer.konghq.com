---
title: request update
---

## Command Description

Update a request

## Syntax

`request update [options] <id>`

## Local Flags

- `--collection <id|name>`: Scope search to a specific collection
- `--name <name>`: New request name
- `--method <method>`: HTTP method
- `--url <url>`: Request URL
- `--description <desc>`: Request description
- `-H, --header <header...>`: Headers (format: "Name: Value")
- `-p, --param <param...>`: Query params (format: "name=value")
- `--body <body>`: Request body
- `--mime <type>`: Body MIME type
- `--auth <auth>`: Auth (none, bearer:token, basic:user:pass, digest:user:pass, apikey:key:value:addTo, oauth2:key=value;...)

## Global Flags

- `--project <path>`: Path to the Git Project directory (defaults to current directory)
- `--agent`: Output structured JSON for agent/LLM consumption
- `--verbose`: Show detailed logs

