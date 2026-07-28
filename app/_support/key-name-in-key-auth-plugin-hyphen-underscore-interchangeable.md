---
title: "`key_names` parameter in Key Auth plugin: hyphen and underscore are interchangeable"
content_type: support
description: This behavior is due to the implementation of an external library and is as per design.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: Why do hyphens and underscores work interchangeably in the `key_names` parameter of the key-auth plugin?
  a: |
    This is due to the implementation of an external library and is by design. Defining `key_names` with an underscore (e.g. `client_id`) matches headers using either a hyphen or an underscore, but defining it with a hyphen (e.g. `client-id`) requires an exact hyphen match in the header.
related_resources: []
---

## Problem

Issue:

When specifying the `key_names` parameter within the config of the `key-auth` plugin, the following behavior is observed:

<!--vale off -->
{% table %}
columns:
  - title: Defined in Config
    key: defined_in_config
  - title: Used in Header
    key: used_in_header
  - title: Successful
    key: successful
rows:
  - defined_in_config: "`client-id`"
    used_in_header: "`client-id`"
    successful: "Yes"
  - defined_in_config: "`client-id`"
    used_in_header: "`client_id`"
    successful: "No"
  - defined_in_config: "`client_id`"
    used_in_header: "`client-id`"
    successful: "Yes"
  - defined_in_config: "`client_id`"
    used_in_header: "`client_id`"
    successful: "Yes"
{% endtable %}
<!--vale on -->

It could be expected that only exact matches between config and header were successful, however as per the table above this is not the case.

## Solution

This behavior is due to the implementation of an external library and is as per design. If customers raise an issue with this behavior, an exact match between header and config will be required if they define `client-id` in the configuration rather than `client_id`.
