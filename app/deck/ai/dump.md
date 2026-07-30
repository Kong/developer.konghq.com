---
title: deck ai dump
description: Export the current state of {{ site.ai_gateway }} to a file.

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
  - text: deck ai commands
    url: /deck/ai/
---
The `deck ai dump` command reads {{site.ai_gateway}} entities from Kong and writes them to a local file in {{site.ai_gateway}} format.

The command only exports entities that have the `managed_by:deck-ai` tag.

The output can be written as either YAML or JSON, controlled by the `--format` flag.

{:.info}
> The following commands will back up **all** of the configuration in to a single file. See [tags](/deck/gateway/tags/) to learn how to segment configuration.

## {{ site.konnect_short_name }}

decK can export one control plane at a time from {{ site.konnect_short_name }}. To choose which control plane is backed up, specify the `--konnect-control-plane-name` flag:

```bash
deck ai dump \
  -o $YOUR_CP_NAME.yaml \
  --konnect-control-plane-name $YOUR_CP_NAME \
  --konnect-token $KONNECT_TOKEN
```

## Single workspace

If you're using the default Workspace, decK automatically identifies the Workspace to back up:

```bash
deck ai dump -o kong.yaml
```

To back up a different Workspace, pass the `-w` flag:

```bash
deck ai dump -w $WORKSPACE_NAME -o $WORKSPACE_NAME.yaml
```

## Command usage

{% include_cached deck/help/ai/dump.md %}