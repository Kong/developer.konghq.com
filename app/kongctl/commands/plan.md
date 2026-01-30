---
title: kongctl plan
content_type: reference
description: Generate a plan to preview changes before applying them.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - declarative-config
  - cli
breadcrumbs:
  - /kongctl/
  - /kongctl/commands/
---

The `kongctl plan` command generates a plan showing what changes will be made to {{site.konnect_short_name}} resources without actually applying them.

## Syntax

```bash
kongctl plan -f <config-file> [flags]
```

## Description

The `plan` command:

1. Reads your declarative configuration files
2. Queries current {{site.konnect_short_name}} state
3. Calculates differences
4. Outputs a plan showing what will be created, updated, or deleted
5. Optionally saves the plan to a file for later use with `apply`

This is useful for:
* Previewing changes before applying them
* Review workflows in pull requests
* Creating approval gates in CI/CD pipelines
* Debugging configuration issues

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `-f`, `--file` | string | Configuration file or directory (can be specified multiple times) |
| `--output-file` | string | Save plan to a JSON file |
| `--output` | string | Output format: `table` (default) or `json` |

## Examples

### Generate a plan from a single file

```bash
kongctl plan -f my-config.yaml
```

### Generate a plan from multiple files

```bash
kongctl plan -f portal.yaml -f apis.yaml
```

### Save plan to a file

```bash
kongctl plan -f config.yaml --output-file plan.json
```

This creates a plan artifact that can be:
* Committed to version control
* Reviewed in pull requests
* Applied later with `kongctl apply --plan plan.json`

### JSON output

```bash
kongctl plan -f config.yaml --output json
```

## Example output

```
Plan: 2 to create, 1 to update, 0 to delete

+ Portal: my-developer-portal
  └─ Will be created

+ API: users-api
  └─ Will be created

~ Portal: existing-portal
  └─ Description will change from "Old description" to "New description"
```

## Plan file format

When you save a plan with `--output-file`, it creates a JSON file containing:

* All planned changes
* Resource identifiers
* Calculated differences
* Metadata about the plan

This file can be used with `kongctl apply --plan` to apply the exact changes that were reviewed.

## CI/CD workflow

Typical CI/CD workflow using plans:

```bash
# In pull request: generate and review plan
kongctl plan -f config/ --output-file plan.json

# After approval: apply the plan
kongctl apply --plan plan.json
```

See the [CI/CD integration guide](/kongctl/declarative/ci-cd/) for complete examples.

## Command usage

{% include_cached kongctl/help/plan.md %}

## Related resources

* [kongctl apply](/kongctl/commands/apply/)
* [kongctl diff](/kongctl/commands/diff/)
* [Declarative configuration guide](/kongctl/declarative/)
* [CI/CD integration](/kongctl/declarative/ci-cd/)
