---
title: Workspaces
description: Manage configuration in multiple Workspaces.

content_type: reference
layout: reference

works_on:
  - on-prem

tools:
  - deck

breadcrumbs:
  - /deck/
  - /deck/gateway/

related_resources:
  - text: deck gateway commands
    url: /deck/gateway/
---

decK is Workspace-aware, meaning it can interact with multiple Workspaces.

{:.info}
> Workspaces are a {{ site.ee_product_name }} concept, and are not applicable to {{ site.konnect_short_name }}.

## Manage one Workspace at a time

To manage the configuration of a specific Workspace, use the `--workspace` flag with [`deck gateway sync`](/deck/gateway/sync/), [`deck gateway diff`](/deck/gateway/diff/), [`deck gateway dump`](/deck/gateway/dump/), or [`deck gateway reset`](/deck/gateway/reset/).

For example, to export the configuration of the Workspace `my-workspace`:

```sh
deck gateway dump --workspace my-workspace
```

If you don't specify a `--workspace` flag, decK uses the `default` Workspace.

To set a Workspace directly in the state file, use the `_workspace` parameter. For example:

```yaml
_format_version: "3.0"
_workspace: default
services:
  - name: example_service
```

{:.info}
> **Note:** decK can't delete Workspaces. If you use `--workspace` or
> `--all-workspaces` with `deck gateway reset`, decK deletes the entire configuration inside the Workspace, but not the Workspace itself.

## Manage multiple Workspaces

You can manage the configurations of all Workspaces in {{site.ee_product_name}} with the `--all-workspaces` flag:

```sh
deck gateway dump --all-workspaces
```

This creates one configuration file per Workspace.

{:.warning}
> Be careful when using the `--all-workspaces` flag to avoid overwriting the wrong Workspace. We recommend using the singular `--workspace` flag in most situations.

However, since a `workspace` is an isolated unit of configuration, decK doesn't allow the deployment of multiple Workspaces at a time. Therefore, each Workspace configuration file must be deployed individually:

```sh
deck gateway sync workspace1.yaml --workspace workspace1
```

```sh
deck gateway sync workspace2.yaml --workspace workspace2
```
