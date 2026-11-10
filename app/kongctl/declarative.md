---
title: Declarative configuration with kongctl

description: Learn how to manage {{site.konnect_product_name}} infrastructure as code using declarative YAML configuration.

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  # - text: CI/CD integration guide
  #   url: /kongctl/ci-cd/
  - text: Get started with kongctl
    url: /kongctl/get-started/
  - text: Use kongctl with AI agent skills
    url: /kongctl/skills/
  - text: Supported resources
    url: /kongctl/supported-resources/
  - text: Troubleshooting kongctl
    url: /kongctl/troubleshooting/
  - text: Examples directory
    url: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/
next_steps:
  - text: Example declarative configurations
    url: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative
  - text: Use kongctl with AI agent skills
    url: /kongctl/skills/
  - text: Learn about supported resources
    url: /kongctl/supported-resources/
  - text: Learn about kongctl authorization options
    url: /kongctl/authentication/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Using kongctl and deck for full API platform management
    url: /kongctl/kongctl-and-deck/
  - text: View the {{site.konnect_short_name}} API reference
    url: /konnect-api/
---

Manage {{site.konnect_product_name}} resources by declaring their desired state in YAML. kongctl
queries {{site.konnect_short_name}}, calculates a change plan, and executes it. It does not maintain
a local state file. You can review changes directly with `diff` or save a JSON
plan for review and later execution.

Namespaces define ownership and reconciliation boundaries. Use distinct
namespaces for resources synchronized independently, such as each team's
development and production environments. Profiles select credentials and
configuration; they do not create ownership boundaries.

## Quick start

Install kongctl using the [installation instructions](/kongctl/#installation),
then authenticate with `kongctl login`. Save this manifest as `portal.yaml`:

```yaml
portals:
  - ref: developer-portal
    name: developer-portal
    display_name: Developer Portal
    kongctl:
      namespace: docs-dev
```

Preview the creates and updates, then apply the configuration:

```shell
kongctl diff --mode apply -f portal.yaml
kongctl apply -f portal.yaml
kongctl get portals
```

Use `kongctl explain portal` to inspect accepted fields and
`kongctl scaffold portal` to generate starter YAML for your installed version.
For field definitions and supported resource types, see the
[Declarative Resource Reference](/kongctl/supported-resources/).

## Choose a workflow

| Goal | Command | Deletion behavior |
| --- | --- | --- |
| Create and update | `apply` | Does not prune omitted resources |
| Reconcile desired state | `sync` | Prunes explicitly scoped collections |
| Remove selected resources | `delete` | Deletes selected resources |
| Review changes | `diff --mode <mode>` | Previews the selected mode |

Execution commands generate a plan internally. For a separate review step:

```shell
kongctl plan --mode apply -f portal.yaml --output-file plan.json
kongctl diff --plan plan.json
kongctl apply --plan plan.json
```

Saved apply, sync, and delete plans require the matching execution command.

## Find detailed behavior

Read the topic matching your task. Each page includes examples and the technical
rules needed to interpret them. For schema details, use
`kongctl explain <resource>.<field>` before guessing field names or tags.

### [Configuration files and resource identity](/kongctl/declarative/configuration/)

Choose identifiers, organize nested or root declarations, and load local or
remote files.

### [Ownership, namespaces, and protection](/kongctl/declarative/ownership/)

Set namespaces, defaults, protection, and ownership guardrails.

### [Planning, reviewing, and executing changes](/kongctl/declarative/planning/)

Choose commands, review saved plans, and understand execution and recovery.

### [Sync scope and deletion safety](/kongctl/declarative/sync/)

Understand omissions, empty collections, singletons, and deletion scope.

### [References and external resource lookups](/kongctl/declarative/references/)

Link declarations and look up existing resources, including scoped parents.

### [Reusable configuration templates](/kongctl/declarative/templates/)

Reuse configuration and understand inheritance and merge rules.

### [File values and path boundaries](/kongctl/declarative/files/)

Load file content, extract values, and choose path boundaries.

### [Environment values and saved plans](/kongctl/declarative/environment-values/)

Choose deferred or stored values, types, and saved-plan behavior.

### [Write-only secrets and rotation](/kongctl/declarative/secrets/)

Create and rotate write-only values without embedding them in plans.

### [Managing multiple environments](/kongctl/declarative/environments/)

Reuse a manifest across independently managed dev and prod environments.

### [Resource-specific declarative behavior](/kongctl/declarative/resource-behavior/)

Check API operation removal, portal webhooks, and {{site.ai_gateway}} lifecycle rules.

### [Managing Gateway configuration with decK](/kongctl/kongctl-and-deck/)

Orchestrate Gateway state files through control planes.

### [Patching tagged configuration files](/kongctl/declarative/patching/)

Edit tagged YAML without resolving its values.

## AI-assisted declarative setup

Install the bundled agent skills from the repository where your agent works:

```shell
kongctl install skills
```

Preview installation with `kongctl install skills --dry-run`. Use the
declarative skill to discover schemas and draft manifests, then review the
resulting plan before applying changes. Agents can follow the topic links in
this guide to load the detailed behavior needed for the current task.

## Examples and troubleshooting

Browse [example
configurations](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/)
for complete manifests. Use the [GitHub Actions quickstart][cicd] to automate
diffs on pull requests and apply merged configuration. See
[Troubleshooting](/kongctl/troubleshooting/) for authentication, planning, and
file-loading failures.

[cicd]: https://developer.konghq.com/kongctl/ci-cd/github-actions/

See [Use kongctl with AI agent skills](/kongctl/skills/) for agent setup.
