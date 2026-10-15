---
title: Workspaces
description: Manage configuration in multiple Workspaces.

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

decK is Workspace-aware, meaning it can interact with multiple Workspaces.

## Manage one Workspace at a time

To manage the configuration of a specific Workspace, use the `--workspace` flag with [`deck gateway sync`](/deck/gateway/sync/), [`deck gateway diff`](/deck/gateway/diff/), [`deck gateway dump`](/deck/gateway/dump/), or [`deck gateway reset`](/deck/gateway/reset/).

For example, to export the configuration of the Workspace `my-workspace`:

{% navtabs "manage one workspace" %}
{% navtab "Self-managed" %}
```sh
deck gateway dump --workspace my-workspace
```
{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}
```sh
deck gateway dump --workspace my-workspace --konnect-control-plane-name $YOUR_CP_NAME
```
{% endnavtab %}
{% endnavtabs %}

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

You can manage the configurations of all Workspaces with the `--all-workspaces` flag:

{% navtabs "manage multiple workspaces" %}
{% navtab "Self-managed" %}
```sh
deck gateway dump --all-workspaces
```
{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}
```sh
deck gateway dump --all-workspaces --konnect-control-plane-name $YOUR_CP_NAME
```
{% endnavtab %}
{% endnavtabs %}

This creates one configuration file per Workspace.

{:.warning}
> Be careful when using the `--all-workspaces` flag to avoid overwriting the wrong Workspace. We recommend using the singular `--workspace` flag in most situations.

However, since a `workspace` is an isolated unit of configuration, decK doesn't allow the deployment of multiple Workspaces at a time. Therefore, each Workspace configuration file must be deployed individually:

{% navtabs "deploy workspace specific config" %}
{% navtab "Self-managed" %}
```sh
deck gateway sync workspace1.yaml --workspace workspace1
```
{% endnavtab %}
{% navtab "{{site.konnect_short_name}}" %}
```sh
deck gateway sync workspace1.yaml --workspace workspace1 --konnect-control-plane-name $YOUR_CP_NAME
```
{% endnavtab %}
{% endnavtabs %}
