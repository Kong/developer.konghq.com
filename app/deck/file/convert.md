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
  - text: Convert Gateway entity config from 2.8 LTS to 3.4 LTS
    url: /gateway/upgrade/convert-lts-28-34/
  - text: Convert Gateway entity config from 3.4 LTS to 3.10 LTS
    url: /gateway/upgrade/convert-lts-34-310/
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
  - path: |
      `2.8` to `3.4` {% new_in 1.47.0 %}
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
  - path: |
      `3.4` to `3.10` {% new_in 1.51.0 %}
    transforms: |
      - Any plugins that use Redis configurations:
        - Transform `redis.cluster_addresses` into `redis.cluster_nodes`
        - Transform `redis.sentinel_addresses` into `redis.sentinel_nodes`
      - AI plugins:
        - Transform `model.options.upstream_path` into `model.options.upstream_url`
      - AI Rate Limiting Advanced plugin:
        - Transform `llm_providers.window_size` from a single value to a list
{% endtable %}

## Command usage

{% include_cached deck/help/file/convert.md %}
