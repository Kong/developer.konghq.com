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
  - text: Get started with kongctl
    url: /kongctl/get-started/
---

The kongctl declarative configuration engine only considers resources that have a `kongctl.namespace` label matching the namespace values given to it during planning and execution.
You may want to bring an existing {{site.konnect_short_name}} resource under declarative management if it was created outside of kongctl.
The `adopt` command lets you add a namespace label to existing {{site.konnect_short_name}} resources without modifying any other fields.
Once you adopt a resource, add it to your configuration set to manage it declaratively going forward.

## Examples

Adopt a portal by name:

```shell
kongctl adopt portal my-portal --namespace team-alpha
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

If the resource already has a `KONGCTL-namespace` label, the command fails
without making changes.

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
    description: "Adopt an existing Konnect DCR provider into namespace management."
  - command: |
      [kongctl adopt event-gateway](/kongctl/adopt/event-gateway/)
    description: "Adopt an existing Konnect Event Gateway into namespace management."
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
