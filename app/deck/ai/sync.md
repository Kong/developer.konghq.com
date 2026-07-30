---
title: deck ai sync
description: Update {{site.ai_gateway}} to match the state defined in the provided configuration.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/ai/

related_resources:
  - text: deck gateway commands
    url: /deck/ai/
---

The `deck ai sync` command reads {{site.ai_gateway}} configuration files and configures the target {{site.ai_gateway}} to match the values specified in your declarative configuration.
It tags every managed entity with `managed_by:deck-ai`.

This is the direct equivalent of running `deck file ai2kong` followed by `deck gateway sync` on the result.

{:.danger}
> Any configuration in {{site.ai_gateway}} that isn't present in the provided declarative configuration file **will be deleted** using `deck ai sync`. 
> To apply a partial configuration [use tags](/deck/gateway/tags/).

The `deck ai sync` command can accept one or more files as positional arguments:

```bash
# Sync a single file
deck ai sync kong.yaml
```

In addition to positional arguments, `deck ai sync` can read input from `stdin` for use in pipelines:

```bash
# Remove example-service from the file before syncing
cat kong.yaml | yq 'del(.services[] | select(.name == "example-service"))' | deck ai sync
```

## Syncing multiple files

{:.warning}
> Syncing multiple files at once causes decK to merge all of the provided files in to a single configuration before syncing. 
> To split your configuration in to independent units, [use tags](/deck/gateway/tags/).

decK can construct a state by combining multiple JSON or YAML files inside a directory instead of a single file.

In most use cases, a single file will suffice, but you might want to use multiple files if:

- You want to organize the files for each Service. In this case, you
  can have one file per Service, and keep the Service, its associated Routes, Plugins, and other entities in that file.
- You have a large configuration file and want to break it down into smaller digestible chunks.

```bash
# Sync multiple files
deck ai sync services.yaml consumers.yaml
```

```bash
# Sync a whole directory
deck ai sync directory/*.yaml
```

## Command usage

{% include_cached deck/help/ai/sync.md %}