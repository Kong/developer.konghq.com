---
title: kongctl get
content_type: reference
description: Retrieve and list Kong Konnect resources.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - cli
breadcrumbs:
  - /kongctl/
  - /kongctl/commands/
---

The `kongctl get` command retrieves and lists {{site.konnect_short_name}} resources.

## Syntax

```bash
kongctl get <resource-type> [resource-name] [flags]
```

## Description

Use `get` to view resources in your {{site.konnect_short_name}} organization. You can:

* List all resources of a type
* Get details for a specific resource by name
* Filter and format output
* Use jq expressions for advanced filtering

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `--output`, `-o` | string | Output format: `table` (default), `json`, or `yaml` |
| `--jq` | string | jq expression to filter JSON output |

## Resource types

Common resource types include:

* `apis` - API specifications
* `api` - Specific API (requires name)
* `portals` - Developer portals
* `portal` - Specific portal (requires name)
* `control-planes` - Control planes
* `control-plane` - Specific control plane (requires name)
* `me` - Current user information

For a complete list, see [Supported Resources](/kongctl/reference/supported-resources/).

## Examples

### List all APIs

```bash
kongctl get apis
```

### Get a specific API

```bash
kongctl get api my-api
```

### JSON output

```bash
kongctl get apis --output json
```

### YAML output

```bash
kongctl get api my-api --output yaml
```

### Filter with jq

List APIs with a specific tag:
```bash
kongctl get apis --output json --jq '.[] | select(.labels.env == "production")'
```

Get just API names:
```bash
kongctl get apis --output json --jq '.[].name'
```

### Check authentication

Verify your current user:
```bash
kongctl get me
```

## Output formats

### Table (default)

Human-readable table format:
```
NAME        ID                                      CREATED
my-api      550e8400-e29b-41d4-a716-446655440000   2025-01-15
users-api   6ba7b810-9dad-11d1-80b4-00c04fd430c8   2025-01-20
```

### JSON

Machine-readable JSON array:
```json
[
  {
    "id": "550e8400-e29b-41d4-a716-446655440000",
    "name": "my-api",
    "description": "My API",
    "created_at": "2025-01-15T10:00:00Z"
  }
]
```

### YAML

YAML format suitable for declarative configuration:
```yaml
- id: 550e8400-e29b-41d4-a716-446655440000
  name: my-api
  description: My API
  created_at: 2025-01-15T10:00:00Z
```

## Command usage

{% include_cached kongctl/help/get.md %}

## Related resources

* [Supported resources reference](/kongctl/reference/supported-resources/)
* [Authentication](/kongctl/authentication/)
* [kongctl view command](/kongctl/commands/view/)
