---
title: Use kongctl with AI agent skills
description: Install kongctl agent skills to help coding agents manage kongctl configuration.
content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

tags:
  - cli
  - declarative-config

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: kongctl install skills
    url: /kongctl/install/skills/
  - text: kongctl explain
    url: /kongctl/explain/
  - text: kongctl scaffold
    url: /kongctl/scaffold/

next_steps:
  - text: Install kongctl agent skills
    url: /kongctl/install/skills/
  - text: Manage {{site.konnect_short_name}} resources declaratively
    url: /kongctl/declarative/
  - text: Learn about supported resources
    url: /kongctl/supported-resources/
  - text: Use kongctl and decK for full API platform management
    url: /kongctl/kongctl-and-deck/
---

`kongctl` includes skills for AI coding agents that work with
{{site.konnect_short_name}} resources from a repository. Skills give an agent
product-specific instructions and workflows while `kongctl` remains the source
of truth for schema discovery, planning, and execution.

Install the bundled skills from the root of the repository where your agent
will work:

```bash
kongctl install skills
```

Preview the files and symlinks before writing them:

```bash
kongctl install skills --dry-run
```

By default, the installer writes skill files to `.kongctl/skills/` and creates
symlinks for supported agent tooling under `.agents/skills/` and
`.claude/skills/`.

## Bundled skills

### `kongctl-declarative`

Use `kongctl-declarative` when you want an agent to help set up or maintain
declarative configuration for {{site.konnect_short_name}}. The skill helps an
agent:

- Discover supported resource fields with `kongctl explain`.
- Generate starter YAML with `kongctl scaffold`.
- Create manifests for APIs, Dev Portals, control planes, and other supported
  resources.
- Integrate decK Gateway state through `_deck`.
- Generate API configuration from OpenAPI documents.
- Work through plan, diff, apply, sync, delete, and adopt workflows.
- Scaffold CI/CD workflows for declarative configuration.

### `kongctl-extension-builder`

Use `kongctl-extension-builder` when you want an agent to help create,
validate, or test a local `kongctl` CLI extension.

## Safe workflow

Agent-generated configuration should be reviewed before it changes
{{site.konnect_short_name}}. A typical workflow is:

1. Install skills with `kongctl install skills`.
1. Ask the agent to use `kongctl explain` and `kongctl scaffold` before
   hand-writing unfamiliar resources or fields.
1. Review the generated YAML in your repository.
1. Preview changes with `kongctl diff --mode apply` or `kongctl plan`.
1. Apply reviewed changes with `kongctl apply` or `kongctl sync`.

Use the [`kongctl install skills`](/kongctl/install/skills/) command reference
for the complete command syntax.
