---
title: deck file merge
description: Merge multiple files in to a single file, leaving env variables in place.

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/file/

related_resources:
  - text: deck file render
    url: /deck/file/render/
  - text: Using environment variables with decK
    url: /deck/configuration/#environment-variables

tags:
  - declarative-config
---

The `deck file merge` command merges multiple declarative configuration files in to a single file. This is useful at the end of your pipeline when linting and validation steps are run.

Unlike [`deck file render`](/deck/file/render/), environment variables are not evaluated by `deck file merge`. In addition, `deck file merge` can operate on partial configuration files, unlike `deck file render`.

The provided files can be in either JSON or YAML format.

```bash
deck file merge one.yaml two.yaml -o complete.yaml
```

## Merge algorithm

The merge algorithm works in the following way:

- Top level arrays are concatenated
- Top level scalar values take the value from the last file passed as an argument

`deck file merge` does not perform any validations.

## Command usage

{% include_cached deck/help/file/merge.md %}
