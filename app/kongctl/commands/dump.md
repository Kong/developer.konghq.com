---
title: kongctl dump
content_type: reference
description: Export current Kong Konnect state to YAML configuration.
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

The `kongctl dump` command exports your current {{site.konnect_short_name}} state to declarative YAML configuration files.

## Syntax

```bash
kongctl dump [flags]
```

## Description

The `dump` command:

1. Queries all resources in your {{site.konnect_short_name}} organization
2. Converts them to declarative YAML format
3. Outputs to stdout or saves to a file

This is useful for:
* Creating backups of your configuration
* Migrating configurations between environments
* Adopting existing resources into declarative management
* Generating templates for new resources
* Disaster recovery

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `--output-file` | string | Save output to a file instead of stdout |
| `--resource-type` | string | Dump only specific resource type(s) |
| `--format` | string | Output format: `yaml` (default) or `json` |

## Examples

### Dump to stdout

```bash
kongctl dump
```

### Save to a file

```bash
kongctl dump --output-file current-state.yaml
```

### Dump specific resource types

```bash
kongctl dump --resource-type portals --output-file portals.yaml
```

### JSON format

```bash
kongctl dump --format json --output-file state.json
```

### Dump and edit

```bash
# Dump current state
kongctl dump --output-file state.yaml

# Edit the file
vim state.yaml

# Apply changes back
kongctl apply -f state.yaml
```

## Example output

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: my-developer-portal
  id: 550e8400-e29b-41d4-a716-446655440000
spec:
  displayName: "Developer Portal"
  description: "API documentation for developers"
  isPublic: true
  createdAt: "2025-01-15T10:00:00Z"
---
apiVersion: v1
kind: API
metadata:
  name: users-api
  id: 6ba7b810-9dad-11d1-80b4-00c04fd430c8
spec:
  displayName: "Users API"
  description: "User management API"
  version: "1.0.0"
```

## Use cases

### Backup configuration

Create regular backups:
```bash
kongctl dump --output-file "backup-$(date +%Y%m%d).yaml"
```

### Adopt existing resources

If you created resources manually or through the UI, dump them to start managing declaratively:

```bash
# Export current state
kongctl dump --output-file current.yaml

# Review and clean up the file
vim current.yaml

# Now manage with declarative config
kongctl apply -f current.yaml
```

### Migrate between environments

```bash
# Export from staging
kongctl dump --output-file staging-config.yaml

# Review and modify for production
vim staging-config.yaml

# Apply to production (different credentials/region)
kongctl apply -f staging-config.yaml --region us
```

### Create templates

Export an existing resource to use as a template:

```bash
# Dump a specific portal
kongctl get portal my-portal --output yaml > template.yaml

# Edit the template
vim template.yaml

# Create new portal from template
kongctl apply -f template.yaml
```

## Metadata handling

The dumped configuration includes:
* Resource IDs (for reference)
* Creation timestamps (read-only)
* All user-configurable fields

When you apply a dumped configuration:
* IDs are used to match existing resources
* Timestamps and other read-only fields are ignored
* Only user-configurable fields are applied

## Command usage

{% include_cached kongctl/help/dump.md %}

## Related resources

* [kongctl adopt](/kongctl/commands/adopt/)
* [kongctl apply](/kongctl/commands/apply/)
* [Declarative configuration guide](/kongctl/declarative/)
* [Supported resources reference](/kongctl/reference/supported-resources/)
