---
title: kongctl list api
description: "List APIs."
content_type: reference
layout: reference


works_on:
  - on-prem
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/
  - /kongctl/list/

related_resources:
  - text: kongctl list commands
    url: /kongctl/list/
---

List APIs.

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl list api attributes](/kongctl/list/api/#kongctl-list-api-attributes)
    description: "List API attributes."
  - command: |
      [kongctl list api documents](/kongctl/list/api/#kongctl-list-api-documents)
    description: "List API documents."
  - command: |
      [kongctl list api implementations](/kongctl/list/api/#kongctl-list-api-implementations)
    description: "List API implementations."
  - command: |
      [kongctl list api publications](/kongctl/list/api/#kongctl-list-api-publications)
    description: "List API publications."
  - command: |
      [kongctl list api versions](/kongctl/list/api/#kongctl-list-api-versions)
    description: "List API versions."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/list/api/index.md %}

### kongctl list api attributes

List API attributes.

{% include_cached /kongctl/help/list/api/attributes.md %}

### kongctl list api documents

List API documents.

{% include_cached /kongctl/help/list/api/documents.md %}

### kongctl list api implementations

List API implementations.

{% include_cached /kongctl/help/list/api/implementations.md %}

### kongctl list api publications

List API publications.

{% include_cached /kongctl/help/list/api/publications.md %}

### kongctl list api versions

List API versions.

{% include_cached /kongctl/help/list/api/versions.md %}
