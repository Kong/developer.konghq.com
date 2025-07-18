---
title: deck gateway sync
description: Update {{ site.base_gateway }} to match the state defined in the provided configuration.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/gateway/

related_resources:
  - text: deck gateway commands
    url: /deck/gateway/
---

The `deck gateway sync` command configures the target {{ site.base_gateway }} to match the values specified in your declarative configuration.

{:.danger}
> Any configuration in {{ site.base_gateway }} that isn't present in the provided declarative configuration file **will be deleted** using `deck gateway sync`. To apply a partial configuration [use tags](/deck/gateway/tags/).

The `deck gateway sync` command can accept one or more files as positional arguments:

```bash
# Sync a single file
deck gateway sync kong.yaml
```

In addition to positional arguments, `deck gateway sync` can read input from `stdin` for use in pipelines:

```bash
# Remove example-service from the file before syncing
cat kong.yaml | yq 'del(.services[] | select(.name == "example-service"))' | deck gateway sync
```

## Syncing multiple files

{:.warning}
> Syncing multiple files at once causes decK to merge all of the provided files in to a single configuration before syncing. To split your configuration in to independent units, [use tags](/deck/gateway/tags/).

decK can construct a state by combining multiple JSON or YAML files inside a directory instead of a single file.

In most use cases, a single file will suffice, but you might want to use multiple files if:

- You want to organize the files for each Service. In this case, you
  can have one file per Service, and keep the Service, its associated Routes, Plugins, and other entities in that file.
- You have a large configuration file and want to break it down into smaller digestible chunks.

```bash
# Sync multiple files
deck gateway sync services.yaml consumers.yaml
```

```bash
# Sync a whole directory
deck gateway sync directory/*.yaml
```

## Command usage

{% include_cached deck/help/gateway/sync.md %}