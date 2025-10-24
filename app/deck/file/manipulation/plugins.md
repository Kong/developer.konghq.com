---
title: Managing plugins with decK
short_title: deck file add-plugins
description: Manage plugin configurations in a Kong declarative configuration file.

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

related_resources:
  - text: Kong Plugin Hub
    url: /plugins/
  - text: Plugin entity
    url: /gateway/entities/plugin/
---

Adding or managing plugins is a common use case for platform teams. The `deck file` command allows you to add or update a plugin configuration programmatically.

If the plugin being added already exists, the `add-plugin` command won't edit the plugin unless the `--overwrite` flag is provided, or `overwrite: true` is specified in the plugin configuration file.

The `deck file add-plugins` command outputs the patched file to `stdout` by default. You can provide a path to a file using `-o ./config.yaml` to write the updated configuration to a file on disk.

## Add a new plugin

You can run the following examples using `deck file add-plugins -s ./kong.yaml plugin1.yaml`.

Multiple plugin definition files can be passed to the command e.g. `deck file add-plugins -s ./kong.yaml  plugin1.yaml plugin1.yaml`.

```yaml
# plugin.yaml
add-plugins:
  - selectors:
      - $..services[*]
    overwrite: false
    plugins:
      - name: request-termination
        config:
          status_code: 403
          message: Scheduled maintenance in progress
```

## Update specific configuration values

The `deck file add-plugins` command configures a complete set of plugin configuration. To edit specific values, you can use the `deck file patch` command.

To update the `request-termination` plugin above to return a different message:

```yaml
patches:
  - selectors:
      - $.services[*].plugins[?(@.name=='request-termination')].config
    values:
      message: "Installing new bits and bytes"
```

For more information, see the [deck file patch](/deck/file/manipulation/patch/) documentation.

## Command usage

{% include_cached deck/help/file/add-plugins.md %}