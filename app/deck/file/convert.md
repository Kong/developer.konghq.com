---
title: deck file convert
description: Convert decK files from one format to another, for example {{ site.base_gateway }} 2.x to 3.x

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
  - text: decK gateway commands
    url: /deck/gateway/
  - text: Upgrade to {{ site.base_gateway }} 3.x with decK
    url: /deck/reference/3.0-upgrade/
  - text: Gateway LTS 2.8 to 3.4 upgrade
    url: /gateway/upgrade/lts-upgrade-28-34/
  - text: Gateway LTS 3.4 to 3.10 upgrade
    url: /gateway/upgrade/lts-upgrade-34-310/
  
tags:
  - declarative-config
---

The convert command changes configuration files from one format into another compatible format. For example, a configuration for `kong-gateway-2.x` can be converted into a `kong-gateway-3.x` configuration file.

```bash
deck file convert --input-file kong2x.yaml --from kong-gateway-2.x --to kong-gateway-3.x
```

## Applied transformations

The following table lists the transformations that `deck file convert` performs:

{% table %}
columns:
  - title: Conversion path
    key: path
  - title: Applied transformations
    key: transforms
rows:
  - path: "`kong-gateway-2.x` to `kong-gateway-3.x`"
    transforms: |
      - Prefix any paths that look like a regular expression with a `~`
      - Generate default values for missing `namespace` fields in any Rate Limiting Advanced plugins
      - Convert decK file `_format_version` from 1.1 to 3.0
  - path: "`2.8` to `3.4`"
    transforms: |
      - Prefix any paths that look like a regular expression with a `~`
      - Generate default values for missing `namespace` fields in any Rate Limiting Advanced plugins
      - Convert decK file `_format_version` from 1.1 to 3.0
      - ACL, Bot Detection, IP Restriction, and Canary plugins: 
        - Convert `config.blacklist` to `config.deny`
        - Convert `config.whitelist` to `config.allow`
      - AWS Lambda plugin: 
        - Remove the deprecated `config.proxy_scheme` parameter
      - Pre-Function and Post-Function plugins: 
        - Convert `config.functions` to `config.access`
  - path: "`3.4` to `3.10`"
    transforms: |
      - Any plugins that use Redis configurations:
        - Transform `redis.cluster_addresses` into `redis.cluster_nodes`
        - Transform `redis.sentinel_addresses` into `redis.sentinel_nodes`
      - AI plugins:
        - Transform `model.options.upstream_path` into `model.options.upstream_url`
      - AI Rate Limiting Advanced plugin:
        - Transform `llm_providers.window_size` from a single value to a list
{% endtable %}

## Converting between LTS versions

You can use `deck file convert` to automatically perform many of the changes that occurred between adjacent LTS versions, such as 2.8 and 3.4, or 3.4 and 3.10.

{% navtabs 'convert-entities' %}
{% navtab "Konnect" %}

1. Use an existing backup file, or export the entity configuration an existing installation, for example 3.4:

   ```sh
   deck gateway dump -o kong-3.4.yaml \
     --konnect-token "$YOUR_KONNECT_PAT" \
     --konnect-control-plane-name $YOUR_CP_NAME
   ```

1. Convert the entity configuration:

   ```sh
   deck file convert \
     --from 3.4 \
     --to 3.10 \
     --input-file kong-3.4.yaml \
     --output-file kong-3.10.yaml
   ```

1. Review the output of the command.
   
    `deck file convert` creates a new file and prints warnings and errors for any changes that can't be made automatically. 
    These changes require some manual work, so adjust your configuration accordingly.

1. Validate the converted file in a test environment.

    Make sure to manually audit the generated file before applying the configuration in production. 
    These changes may not be fully correct or exhaustive, so manual validation is strongly recommended.

1. Upload your new configuration to a {{site.konnect_short_name}} control plane:

   ```sh
   deck gateway sync kong-3.10.yaml \
     --konnect-token "$YOUR_KONNECT_PAT" \
     --konnect-control-plane-name $YOUR_CP_NAME
   ```
{% endnavtab %}
{% navtab "Self-managed" %}

1. Use an existing backup file, or export the entity configuration an existing installation, for example 3.4:

   ```sh
   deck gateway dump -o kong-3.4.yaml --all-workspaces
   ```

1. Convert the entity configuration:

   ```sh
   deck file convert \
     --from 3.4 \
     --to 3.10 \
     --input-file kong-3.4.yaml \
     --output-file kong-3.10.yaml
   ```

1. Review the output of the command.
   
    `deck file convert` creates a new file and prints warnings and errors for any changes that can't be made automatically. 
    These changes require some manual work, so adjust your configuration accordingly.

1. Validate the converted file in a test environment.

    Make sure to manually audit the generated file before applying the configuration in production. 
    These changes may not be fully correct or exhaustive, so manual validation is strongly recommended.

1. Upload your new configuration to the new environment:

   ```sh
   deck gateway sync kong-3.10.yaml \
     --workspace default
   ```
{% endnavtab %}
{% endnavtabs %}

## Command usage

{% include_cached deck/help/file/convert.md %}
