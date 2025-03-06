---
title: Plugins
short_title: deck file add-plugins
description: Manage Plugin configurations in Kong declarative configuration file.

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

related_resources:
  - text: All decK documentation
    url: /index/deck/
---

Adding or managing Plugins is a common use case for platform teams. The `deck file` command allows you to add or update a Plugin configuration programmatically.

If the Plugin being added already exists, the `add-plugin` command won't edit the Plugin unless the `--overwrite` flag is provided or `overwrite: true` is specified in the Plugin configuration file.

The `deck file add-plugins` command outputs the patched file to `stdout` by default. You can provide `-o /path/to/config.yaml` to write the updated configuration to a file on disk.

## Add a new Plugin

You can run the following examples using `deck file add-plugins -s /path/to/kong.yaml plugin1.yaml`.

Multiple Plugin definition files can be passed to the command e.g. `deck file add-plugins -s /path/to/kong.yaml  plugin1.yaml plugin1.yaml`.

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

The `deck file add-plugins` command configures a complete set of Plugin configuration. To edit specific values, you can use the `deck file patch` command.

To update the `request-termination` Plugin above to return a different message:

```yaml
patches:
  - selectors:
      - $.services[*].plugins[?(@.name=='request-termination')].config
    values:
      message: "Installing new bits and bytes"
```

For more information, see the [deck file patch](/deck/file/manipulation/patch/) documentation.
