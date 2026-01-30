---
title: kongctl apply
content_type: reference
description: Apply declarative configuration to create or update resources.
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

The `kongctl apply` command applies declarative configuration to create or update {{site.konnect_short_name}} resources.

## Syntax

```bash
kongctl apply -f <config-file> [flags]
```

Or apply from a saved plan:

```bash
kongctl apply --plan <plan-file> [flags]
```

## Description

The `apply` command:

1. Reads your declarative configuration
2. Creates resources that don't exist
3. Updates resources that have changed
4. **Does not delete** resources missing from configuration

This is similar to `kubectl apply` in Kubernetes. If you want to delete resources not in your configuration, use [`kongctl sync`](/kongctl/commands/sync/) instead.

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `-f`, `--file` | string | Configuration file or directory (can be specified multiple times) |
| `--plan` | string | Apply from a saved plan file |
| `--dry-run` | boolean | Show what would be changed without applying |

## Examples

### Apply a single file

```bash
kongctl apply -f my-portal.yaml
```

### Apply multiple files

```bash
kongctl apply -f portal.yaml -f apis.yaml
```

### Apply a directory

```bash
kongctl apply -f ./config/
```

### Apply from a saved plan

```bash
# First generate a plan
kongctl plan -f config/ --output-file plan.json

# Review the plan, then apply it
kongctl apply --plan plan.json
```

### Dry run

Preview changes without applying:
```bash
kongctl apply -f config.yaml --dry-run
```

## Example configuration

Create a file `my-portal.yaml`:

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: my-developer-portal
spec:
  displayName: "Developer Portal"
  description: "API documentation for developers"
  isPublic: true
---
apiVersion: v1
kind: API
metadata:
  name: users-api
spec:
  displayName: "Users API"
  description: "User management API"
  version: "1.0.0"
```

Apply it:
```bash
kongctl apply -f my-portal.yaml
```

## Behavior

### Creates new resources

If a resource doesn't exist in {{site.konnect_short_name}}, `apply` creates it:

```
+ Portal: my-developer-portal
  └─ Created successfully
```

### Updates existing resources

If a resource exists and has changed, `apply` updates it:

```
~ Portal: existing-portal
  └─ Updated description
```

### Ignores unchanged resources

If a resource exists and hasn't changed, `apply` skips it:

```
= Portal: unchanged-portal
  └─ No changes needed
```

### Does not delete

Resources in {{site.konnect_short_name}} that aren't in your configuration are **not deleted**. To delete them, either:

* Use `kongctl delete` manually
* Use [`kongctl sync`](/kongctl/commands/sync/) instead (deletes resources not in config)

## Apply vs Sync

| Command | Creates | Updates | Deletes |
|---------|---------|---------|---------|
| `apply` | ✅ | ✅ | ❌ |
| `sync`  | ✅ | ✅ | ✅ |

Use `apply` for:
* Incremental changes
* Safe deployments
* When you manage only a subset of resources

Use `sync` for:
* Exact state matching
* Full environment management
* When you want to remove orphaned resources

## Command usage

{% include_cached kongctl/help/apply.md %}

## Related resources

* [kongctl plan](/kongctl/commands/plan/)
* [kongctl sync](/kongctl/commands/sync/)
* [kongctl diff](/kongctl/commands/diff/)
* [Declarative configuration guide](/kongctl/declarative/)
