---
title: deck gateway dump
description: Export the current state of {{ site.base_gateway }} to a file.

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

decK can back up the configuration of your running {{ site.base_gateway }} using the `deck gateway dump` command.

See the reference for [Entities managed by decK](/deck/reference/entities/) to find out which entity configurations can be backed up.

The exact command that you need to run changes if you're using [Workspaces](/gateway/entities/workspace/) (on-prem only) or not.

{:.info}
> The following commands will back up **all** of the configuration in to a single file. See [tags](/deck/gateway/tags/) to learn how to segment configuration.

## {{ site.konnect_short_name }}

decK can export one control plane at a time from {{ site.konnect_short_name }}. To choose which control plane is backed up, specify the `--konnect-control-plane-name` flag:

```bash
deck gateway dump \
  -o $YOUR_CP_NAME.yaml \
  --konnect-control-plane-name $YOUR_CP_NAME \
  --konnect-token $KONNECT_TOKEN
```

## Single workspace

If you're using the default Workspace, decK automatically identifies the Workspace to back up:

```bash
deck gateway dump -o kong.yaml
```

To back up a different Workspace, pass the `-w` flag:

```bash
deck gateway dump -w $WORKSPACE_NAME -o $WORKSPACE_NAME.yaml
```

## All workspaces

To back up all Workspaces, pass the `--all-workspaces` flag.
This creates multiple files in the current directory. Each file is named the same as its Workspace:

```bash
deck gateway dump --all-workspaces
```
