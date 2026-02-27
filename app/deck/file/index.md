---
title: File manipulation using decK file
short_title: decK file
description: Manipulate a decK configuration file programmatically. Layer in additional configuration and lint against your governance rules.
weight: 1000

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

tags:
  - declarative-config

search_aliases:
  - declarative configuration

breadcrumbs:
  - /deck/

related_resources:
  - text: decK file manipulation documentation
    url: /deck/file/manipulation/
---

decK's declarative configuration format is the canonical representation of a {{ site.base_gateway }} configuration in text form.

decK provides multiple tools for interacting with this declarative configuration:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [openapi2kong](/deck/file/openapi2kong/)
    description: Convert an OpenAPI specification to {{ site.base_gateway }} Services and Routes.
  - command: |
      [kong2kic](/deck/file/kong2kic/)
    description: Convert a {{site.base_gateway}} declarative configuration file to [{{site.kic_product_name}}](/kubernetes-ingress-controller/) compatible CRDs. Supports both Gateway API and Ingress resources.
  - command: |
      [kong2tf](/deck/file/kong2tf/)
    description: Convert a {{site.base_gateway}} declarative configuration file to Terraform manifests ({{site.konnect_short_name}} only).
{% endtable %}

decK also provides commands to manipulate declarative configuration files:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [patch](/deck/file/manipulation/patch/)
    description: Update values in a {{site.base_gateway}} declarative configuration file.
  - command: |
      [add-plugins](/deck/file/manipulation/plugins/)
    description: Add new plugin configurations to a {{site.base_gateway}} declarative configuration file.
  - command: |
      [add-tags](/deck/file/manipulation/tags/)
    description: Add new tags to a {{site.base_gateway}} declarative configuration file.
  - command: |
      [list-tags](/deck/file/manipulation/tags/)
    description: List all tags in a {{site.base_gateway}} declarative configuration file.
  - command: |
      [remove-tags](/deck/file/manipulation/tags/)
    description: Remove tags to a {{site.base_gateway}} declarative configuration file.
  - command: |
      [merge](/deck/file/merge/)
    description: Merge multiple files in to a single file, leaving `env` variables in place.
  - command: |
      [render](/deck/file/render/)
    description: Render the final configuration sent to the Admin API in a single file.
  - command: |
      [namespace](/deck/file/manipulation/namespace/)
    description: Apply a namespace to Routes in a decK file by path or hostname.
  - command: |
      [convert](/deck/file/convert/)
    description: Convert decK files from one format to another, for example {{site.base_gateway}} 2.x to 3.x.
{% endtable %}

decK provides a [`deck file lint`](/deck/file/lint/) command which can be used to ensure that declarative configuration files meet defined standards before being used to configure {{ site.base_gateway }}.

Finally, the [`deck file validate`](/deck/file/validate/) command validates the state file locally against static schemas. This won't detect any conflicts on the server, but is much faster than [`deck gateway validate`](/deck/gateway/validate/).
