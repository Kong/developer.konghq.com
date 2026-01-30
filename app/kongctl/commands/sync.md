---
title: kongctl sync
content_type: reference
description: Sync Kong Konnect to match declarative configuration exactly.
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

The `kongctl sync` command synchronizes {{site.konnect_short_name}} to match your declarative configuration exactly, including deletions.

## Syntax

```bash
kongctl sync -f <config-file> [flags]
```

## Description

The `sync` command:

1. Reads your declarative configuration
2. Creates resources that don't exist
3. Updates resources that have changed
4. **Deletes resources** that exist in {{site.konnect_short_name}} but are missing from configuration

This makes {{site.konnect_short_name}} match your configuration exactly. Unlike [`kongctl apply`](/kongctl/commands/apply/), which only creates and updates, `sync` also removes resources not defined in your files.

{:.warning}
> **Warning**: `sync` will delete resources in {{site.konnect_short_name}} that are not in your configuration files. Always use `kongctl plan` or `kongctl diff` to preview changes before running `sync`.

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `-f`, `--file` | string | Configuration file or directory (can be specified multiple times) |
| `--dry-run` | boolean | Show what would be changed without applying |

## Examples

### Sync from a single file

```bash
# Preview changes first
kongctl diff -f my-config.yaml

# Then sync
kongctl sync -f my-config.yaml
```

### Sync from multiple files

```bash
kongctl sync -f portal.yaml -f apis.yaml
```

### Sync a directory

```bash
kongctl sync -f ./production-config/
```

### Dry run

Preview all changes including deletions:
```bash
kongctl sync -f config.yaml --dry-run
```

## Behavior

### Creates new resources

Resources in configuration but not in {{site.konnect_short_name}} are created:

```
+ Portal: new-portal
  └─ Will be created
```

### Updates existing resources

Resources that exist but have different values are updated:

```
~ API: existing-api
  └─ Description will change
```

### Deletes missing resources

{:.warning}
Resources in {{site.konnect_short_name}} but not in configuration are **deleted**:

```
- Portal: old-portal
  └─ Will be deleted
```

## Apply vs Sync

| Command | Creates | Updates | Deletes |
|---------|---------|---------|---------|
| `apply` | ✅ | ✅ | ❌ |
| `sync`  | ✅ | ✅ | ✅ |

Use `apply` when:
* Making incremental changes
* Managing a subset of resources
* You want to avoid accidental deletions

Use `sync` when:
* You want exact state matching
* Managing entire environments
* You want to remove orphaned resources
* Implementing GitOps workflows

## Best practices

### Always preview first

Generate a plan before syncing:
```bash
kongctl plan -f config/ --output-file plan.json
# Review plan.json
kongctl apply --plan plan.json  # Safer than direct sync
```

Or use diff:
```bash
kongctl diff -f config/
# Review the output
kongctl sync -f config/
```

### Use namespace isolation

If you manage different resource types in different files, be careful not to accidentally delete resources:

```bash
# ❌ BAD: Only has portals, will delete all APIs
kongctl sync -f portals-only.yaml

# ✅ GOOD: Separate configs for different resource types
kongctl apply -f portals.yaml
kongctl apply -f apis.yaml
```

### Version control

Keep configuration in Git and use sync in CI/CD:

```bash
# CI/CD pipeline
git pull origin main
kongctl sync -f config/production/
```

## Command usage

{% include_cached kongctl/help/sync.md %}

## Related resources

* [kongctl apply](/kongctl/commands/apply/)
* [kongctl plan](/kongctl/commands/plan/)
* [kongctl diff](/kongctl/commands/diff/)
* [Declarative configuration guide](/kongctl/declarative/)
* [CI/CD integration](/kongctl/declarative/ci-cd/)
