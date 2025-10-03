---
title: Modify Headers
name: Modify Headers
content_type: reference
description: Set or remove record headers
products:
    - event-gateway
works_on:
    - konnect
tags:
    - event-gateway

schema:
  api: event-gateway/knep
  path: /schemas/ModifyHeadersPolicy

api_specs:
  - event-gateway/knep

beta: true

phases:
  - produce
  - consume

icon: graph.svg
---

This policy is used to set or remove record headers.

## Use cases

Common use cases for the Modify Headers policy:

<!--vale off-->
{% table %}
columns:
  - title: Use case
    key: use_case
  - title: Description
    key: description
rows:
  - use_case: "[Remove and replace a header](/event-gateway/policies/modify-headers/examples/remove-and-replace-header/)"
    description: Remove a specific header and replace it with a custom header of your choice.
{% endtable %}
<!--vale on-->
