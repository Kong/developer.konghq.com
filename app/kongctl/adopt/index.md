---
title: kongctl adopt
description: Adopt Kong resources using kongctl.

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Adopt existing resources
    url: /kongctl/declarative/adoption/
  - text: Get started with kongctl
    url: /kongctl/get-started/
---

Use `kongctl adopt` to bring existing {{site.konnect_short_name}} resources
under declarative management by assigning namespace ownership metadata.
Adoption preserves resource IDs and configuration. Resources must also be
included in your declarative inputs to manage them going forward.

Add `--declarative-output PATH` to adopt and save the selected resources as
YAML in one command. The destination must be a new file in an existing
directory. Include that file in your configuration inputs, or merge its
contents into your existing files.

Use `--dry-run` to preview ownership changes without changing remote
resources. Combined with `--declarative-output`, it saves proposed
configuration; use a different output path for the actual adoption.

Parent adoption doesn't adopt independently owned children. See
[Adopt existing resources](/kongctl/declarative/adoption/) for child selection,
parent references, and complete workflows.

## Examples

Adopt a {{site.dev_portal}} by name and save its declaration:

```shell
kongctl adopt portal my-portal --namespace team-alpha \
  --declarative-output portal.yaml
```

Adopt a control plane by ID:

```shell
kongctl adopt control-plane 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace platform
```

Adopt a custom dashboard by ID:

```shell
kongctl adopt analytics dashboard 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace analytics
```

If the resource already has namespace ownership metadata, the command fails
without making changes unless you pass `--overwrite-namespace`. The same
rule applies when the existing namespace matches the requested namespace.

## Subcommands

kongctl provides the following tools for adopting Kong resources:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl adopt ai-gateway](/kongctl/adopt/ai-gateway/)
    description: "Adopt an existing {{site.konnect_short_name}} {{site.ai_gateway}} into namespace management."
  - command: |
      [kongctl adopt analytics](/kongctl/adopt/analytics/)
    description: "Adopt {{site.konnect_short_name}} {{site.observability}} resources."
  - command: |
      [kongctl adopt api](/kongctl/adopt/api/)
    description: "Adopt API resources."
  - command: |
      [kongctl adopt auth-strategy](/kongctl/adopt/auth-strategy/)
    description: "Adopt authentication strategies."
  - command: |
      [kongctl adopt control-plane](/kongctl/adopt/control-plane/)
    description: "Adopt control plane configuration."
  - command: |
      [kongctl adopt dcr-provider](/kongctl/adopt/dcr-provider/)
    description: "Adopt an existing {{site.konnect_short_name}} DCR provider into namespace management."
  - command: |
      [kongctl adopt event-gateway](/kongctl/adopt/event-gateway/)
    description: "Adopt an existing {{site.konnect_short_name}} {{site.event_gateway_short}} into namespace management."
  - command: |
      [kongctl adopt identity](/kongctl/adopt/identity/)
    description: "Adopt Kong Identity resources."
  - command: |
      [kongctl adopt konnect](/kongctl/adopt/konnect/)
    description: "Adopt {{site.konnect_short_name}} resources."
  - command: |
      [kongctl adopt organization](/kongctl/adopt/organization/)
    description: "Adopt organization settings."
  - command: |
      [kongctl adopt portal](/kongctl/adopt/portal/)
    description: "Adopt Developer Portal configuration."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/adopt/index.md %}
