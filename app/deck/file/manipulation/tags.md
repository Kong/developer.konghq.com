---
title: Manage tags with decK
short_title: deck file *-tags
description: Manage tags in a Kong declarative configuration file.

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
  - /deck/file/manipulation/

tags:
  - declarative-config
  - federated-config

related_resources:
  - text: Gateway tags
    url: /gateway/tags/
  - text: Federated configuration with decK
    url: /deck/apiops/federated-configuration/

---

Tags are at the core of [federated configuration management](/deck/apiops/federated-configuration/), which allows each team to manage their own config.

Using the `deck file` tag commands, you can add tags to identify configuration lineage automatically without depending on your application teams understanding the process and remembering to apply tags consistently.

## add-tags

The `add-tags` command can add tags to any entity. Here's an example that adds the `team-one` tag to all entities in the provided file:

```bash
deck file add-tags -s ./config.yaml team-one
```

This is useful to track entity ownership when using the [deck file merge](/deck/file/merge/) command to build a single configuration to sync.

To add tags to specific entities only, provide the `--selector` flag. The provided tags will be added only to entities that match the selector

You can add multiple tags at once by providing them as additional arguments, for example: `team-one another-tag and-another`.

### Command usage

{% include_cached deck/help/file/add-tags.md %}

## remove-tags

The opposite of `add-tags`, `remove-tags` allows you delete tags from your configuration file. It will remove the provided tag only by default:

```bash
deck file remove-tags -s ./config.yaml tag_to_remove
```

To keep specific tags and remove all others, pass the `--keep-only` flag:

```bash
deck file remove-tags -s ./config.yaml --keep-only env-prod team-one
```

Finally, to remove tags from specific entities you can pass a `--selector`. This can be combined with `--keep-only` as needed:

```bash
deck file remove-tags -s ./config.yaml \
  --selector "$..services[*]" \
  --keep-only env-prod team-one
```

### Command usage

{% include_cached deck/help/file/remove-tags.md %}

## list-tags

The `list-tags` command outputs all tags found in the file. Any tag that is applied to at least one entity is returned.

```bash
deck file list-tags -s ./config.yaml
```

### Command usage

{% include_cached deck/help/file/list-tags.md %}