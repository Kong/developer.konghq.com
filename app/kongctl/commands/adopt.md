---
title: kongctl adopt
content_type: reference
description: Adopt existing resources for declarative management.
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

The `kongctl adopt` command adopts existing {{site.konnect_short_name}} resources for declarative management without recreating them.

## Syntax

```bash
kongctl adopt -f <config-file> [flags]
```

## Description

The `adopt` command allows you to take control of resources that already exist in {{site.konnect_short_name}} without deleting and recreating them. This is useful when:

* You created resources manually through the UI or API
* You're transitioning from imperative to declarative management
* You want to import resources from another environment

When you adopt a resource:
1. kongctl finds the matching resource in {{site.konnect_short_name}}
2. It associates the resource with your declarative configuration
3. Future `apply` or `sync` operations will update the resource instead of trying to create it

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `-f`, `--file` | string | Configuration file or directory (can be specified multiple times) |
| `--dry-run` | boolean | Show what would be adopted without actually adopting |

## Examples

### Adopt from a configuration file

```bash
kongctl adopt -f my-resources.yaml
```

### Adopt multiple files

```bash
kongctl adopt -f portals.yaml -f apis.yaml
```

### Dry run

Preview what will be adopted:
```bash
kongctl adopt -f config.yaml --dry-run
```

## Workflow: Manual to declarative

If you've been creating resources manually, here's how to adopt them:

### 1. Export existing resources

```bash
kongctl dump --output-file current-state.yaml
```

### 2. Review and organize

Edit the file to keep only resources you want to manage:
```bash
vim current-state.yaml
```

### 3. Adopt the resources

```bash
kongctl adopt -f current-state.yaml
```

### 4. Manage declaratively

Now you can manage these resources with `apply` and `sync`:
```bash
# Make changes to the file
vim current-state.yaml

# Apply changes
kongctl apply -f current-state.yaml
```

## How adoption works

### Matching resources

kongctl matches resources by:
1. **Name**: The `metadata.name` field
2. **Type**: The `kind` field (Portal, API, etc.)

If a resource with the same name and type exists in {{site.konnect_short_name}}, it's adopted.

### Example

Configuration file `my-portal.yaml`:
```yaml
apiVersion: v1
kind: Portal
metadata:
  name: existing-portal
spec:
  displayName: "My Portal"
  description: "Updated description"
```

If a portal named "existing-portal" already exists:
```bash
kongctl adopt -f my-portal.yaml
# ✅ Adopts the existing portal
# ✅ Updates the description
# ❌ Does not create a new portal
```

If it doesn't exist:
```bash
kongctl adopt -f my-portal.yaml
# ℹ️ Portal not found, will be created on next apply
```

## Adopt vs Apply

| Command | If resource exists | If resource doesn't exist |
|---------|-------------------|---------------------------|
| `adopt` | Associates with config, updates if needed | Notes it for creation |
| `apply` | Updates (or creates if needed) | Creates |

Use `adopt` when:
* Transitioning to declarative management
* You want explicit control over which resources to manage
* Importing from another system

Use `apply` for:
* Normal declarative workflows
* When you don't need the extra adoption step

## Command usage

{% include_cached kongctl/help/adopt.md %}

## Related resources

* [kongctl dump](/kongctl/commands/dump/)
* [kongctl apply](/kongctl/commands/apply/)
* [Declarative configuration guide](/kongctl/declarative/)
