---
title: kongctl diff
content_type: reference
description: Show differences between local configuration and remote state.
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

The `kongctl diff` command shows differences between your local declarative configuration and the current state in {{site.konnect_short_name}}.

## Syntax

```bash
kongctl diff -f <config-file> [flags]
```

Or diff a saved plan:

```bash
kongctl diff --plan <plan-file> [flags]
```

## Description

The `diff` command:

1. Reads your declarative configuration
2. Queries the current {{site.konnect_short_name}} state
3. Displays differences in a human-readable format

This is useful for:
* Previewing changes before applying
* Understanding configuration drift
* Debugging issues
* Code reviews

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `-f`, `--file` | string | Configuration file or directory (can be specified multiple times) |
| `--plan` | string | Diff from a saved plan file |
| `--output` | string | Output format: `text` (default) or `json` |

## Examples

### Diff a configuration file

```bash
kongctl diff -f my-config.yaml
```

### Diff multiple files

```bash
kongctl diff -f portal.yaml -f apis.yaml
```

### Diff a saved plan

```bash
kongctl diff --plan plan.json
```

### JSON output

```bash
kongctl diff -f config.yaml --output json
```

## Example output

```
~ Portal: my-developer-portal
  ~ spec.description
    - "Old description"
    + "New description"
  ~ spec.isPublic
    - false
    + true

+ API: new-api
  + Will be created with:
    + name: "new-api"
    + displayName: "New API"

- Portal: deprecated-portal
  - Will be deleted
```

The output uses:
* `~` for resources that will be updated
* `+` for resources that will be created
* `-` for resources that will be deleted (when using `sync`)
* Indentation shows field-level changes

## Understanding the output

### Modified resources

```
~ Portal: my-portal
  ~ spec.displayName
    - "Old Name"
    + "New Name"
```

Shows the resource will be updated, with old value (`-`) and new value (`+`).

### New resources

```
+ API: new-api
  + spec.displayName: "New API"
  + spec.version: "1.0.0"
```

Shows a resource will be created with these fields.

### Deleted resources

```
- Portal: old-portal
```

Shows a resource will be deleted (only when using `sync`, not `apply`).

### No changes

```
= Portal: unchanged-portal
```

Shows the resource exists and matches configuration.

## Diff vs Plan

Both commands show what will change, but with different outputs:

| Command | Output | Use Case |
|---------|--------|----------|
| `diff` | Human-readable text | Quick preview, code reviews |
| `plan` | Structured table or JSON | CI/CD, automation, detailed analysis |

## Workflow example

```bash
# 1. Make changes to your configuration
vim portal.yaml

# 2. Preview the changes
kongctl diff -f portal.yaml

# 3. If changes look good, apply them
kongctl apply -f portal.yaml
```

## Command usage

{% include_cached kongctl/help/diff.md %}

## Related resources

* [kongctl plan](/kongctl/commands/plan/)
* [kongctl apply](/kongctl/commands/apply/)
* [kongctl sync](/kongctl/commands/sync/)
* [Declarative configuration guide](/kongctl/declarative/)
