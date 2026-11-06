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
queries Konnect, calculates a change plan, and executes it. It does not maintain
a local state file. You can review changes directly with `diff` or save a JSON
plan for review and later execution.

Namespaces define ownership and reconciliation boundaries. Use distinct
namespaces for resources synchronized independently, such as each team's
development and production environments. Profiles select credentials and
configuration; they do not create ownership boundaries.

<a id="overview"></a>
<a id="key-principles"></a>

## Quick Start

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

## Choose a Workflow

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

## Find Detailed Behavior

Read the topic matching your task. Each page includes examples and the technical
rules needed to interpret them. For schema details, use
`kongctl explain <resource>.<field>` before guessing field names or tags.

<a id="resource-identity"></a>
<a id="basic-structure"></a>
<a id="hierarchical-vs-flattened-configuration"></a>
<a id="parent-selectors-and-references"></a>
<a id="remote-configuration-files"></a>
<a id="field-validation"></a>
<a id="core-concepts"></a>
<a id="configuration-structure"></a>

<a id="prerequisites"></a>
<a id="create-your-first-configuration"></a>

### [Configuration files and resource identity](/kongctl/declarative/configuration/)

Choose identifiers, organize nested or root declarations, and load local or
remote files.

<a id="protected-resources"></a>
<a id="namespace-management"></a>
<a id="file-level-defaults"></a>
<a id="namespace-and-protected-field-behavior"></a>
<a id="namespace-field-behavior"></a>
<a id="protected-field-behavior"></a>
<a id="namespace-enforcement-flags"></a>
<a id="parent-vs-child-resources"></a>
<a id="kongctl-metadata"></a>

<a id="multi-team-setup"></a>
<a id="security-best-practices"></a>
<a id="common-mistakes-to-avoid"></a>

### [Ownership, namespaces, and protection](/kongctl/declarative/ownership/)

Set namespaces, defaults, protection, and ownership guardrails.

<a id="plan-artifacts"></a>
<a id="how-planning-works"></a>
<a id="why-use-plan-artifacts"></a>
<a id="plan-artifact-workflows"></a>
<a id="basic-plan-review-workflow"></a>
<a id="production-deployment-with-approval"></a>
<a id="returning-to-a-previous-configuration"></a>
<a id="choose-a-command"></a>
<a id="values-and-portability"></a>
<a id="commands-reference"></a>
<a id="cicd-integration"></a>

<a id="plan"></a>
<a id="apply"></a>
<a id="delete"></a>
<a id="diff"></a>
<a id="adopt"></a>
<a id="dump"></a>
<a id="emergency-rollback-using-previous-plan"></a>

### [Planning, reviewing, and executing changes](/kongctl/declarative/planning/)

Choose commands, review saved plans, and understand execution and recovery.


<a id="sync"></a>

### [Sync scope and deletion safety](/kongctl/declarative/sync/)

Understand omissions, empty collections, singletons, and deletion scope.

<a id="external-resources"></a>
<a id="references-and-lookups-in-payload-values"></a>
<a id="nested-yaml-tags"></a>
<a id="external-resources-and-namespaces"></a>
<a id="yaml-tags"></a>

### [References and external resource lookups](/kongctl/declarative/references/)

Link declarations and look up existing resources, including scoped parents.

<a id="template-discovery-and-inheritance"></a>
<a id="merge-rules"></a>
<a id="configuration-templates"></a>

### [Reusable configuration templates](/kongctl/declarative/templates/)

Reuse configuration and understand inheritance and merge rules.

<a id="loading-file-content-to-yaml-fields"></a>
<a id="security-features"></a>
<a id="performance-features"></a>
<a id="value-extraction"></a>

### [File values and path boundaries](/kongctl/declarative/files/)

Load file content, extract values, and choose path boundaries.

<a id="loading-values-from-environment-variables"></a>
<a id="env-behavior"></a>
<a id="storing-typed-environment-values-in-plans"></a>
<a id="parsing-and-serialization-boundaries"></a>
<a id="compatibility-and-saved-plans"></a>

### [Environment values and saved plans](/kongctl/declarative/environment-values/)

Choose deferred or stored values, types, and saved-plan behavior.

<a id="write-only-secret-fields"></a>

### [Write-only secrets and rotation](/kongctl/declarative/secrets/)

Create and rotate write-only values without embedding them in plans.

<a id="environment-management"></a>
<a id="review-and-verify-each-environment"></a>
<a id="best-practices"></a>

### [Managing multiple environments](/kongctl/declarative/environments/)

Reuse a manifest across independently managed dev and prod environments.

<a id="authorizing-api-operation-removal"></a>
<a id="portal-audit-log-webhooks"></a>
<a id="ai-gateway-mcp-server-replacements"></a>
<a id="ai-gateway-config-stores-and-vaults"></a>
<a id="ai-gateway-runtime-tls"></a>
<a id="ai-gateway-23-configuration"></a>

<a id="manage-ai-gateway-declaratively"></a>

### [Resource-specific declarative behavior](/kongctl/declarative/resource-behavior/)

Check API operation removal, portal webhooks, and {{site.ai_gateway}} lifecycle rules.

<a id="resources-managed-by-deck"></a>

### [Managing Gateway configuration with decK](/kongctl/kongctl-and-deck/)

Orchestrate Gateway state files through control planes.

<a id="patching-tagged-configuration"></a>

### [Patching tagged configuration files](/kongctl/declarative/patching/)

Edit tagged YAML without resolving its values.

## AI-Assisted Declarative Setup

Install the bundled agent skills from the repository where your agent works:

```shell
kongctl install skills
```

Preview installation with `kongctl install skills --dry-run`. Use the
declarative skill to discover schemas and draft manifests, then review the
resulting plan before applying changes. Agents can follow the topic links in
this guide to load the detailed behavior needed for the current task.

<a id="examples"></a>
<a id="troubleshooting"></a>
<a id="common-issues"></a>
<a id="debug-mode"></a>
<a id="related-documentation"></a>

## Examples and Troubleshooting

Browse [example
configurations](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/)
for complete manifests. Use the [GitHub Actions quickstart][cicd] to automate
diffs on pull requests and apply merged configuration. See
[Troubleshooting](/kongctl/troubleshooting/) for authentication, planning, and
file-loading failures.

[cicd]: https://developer.konghq.com/kongctl/ci-cd/github-actions/

See [Use kongctl with AI agent skills](/kongctl/skills/) for agent setup.
