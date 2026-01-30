---
title: kongctl api
content_type: reference
description: Call Kong Konnect APIs directly using current authentication.
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

The `kongctl api` command allows you to call {{site.konnect_short_name}} APIs directly using your current authentication credentials.

## Syntax

```bash
kongctl api <path> [flags]
```

## Description

The `api` command provides direct access to {{site.konnect_short_name}} APIs. This is useful when:

* You need to access APIs not yet supported by kongctl commands
* You want to make custom API calls
* You're debugging or experimenting
* You need low-level control

The command automatically:
* Uses your authenticated session (from `kongctl login` or `--pat`)
* Adds required authentication headers
* Targets the correct region endpoint

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `-X`, `--request` | string | HTTP method: `GET` (default), `POST`, `PUT`, `PATCH`, `DELETE` |
| `-d`, `--data` | string | Request body (JSON string) |
| `-H`, `--header` | string | Additional header (can be specified multiple times) |
| `--output` | string | Output format: `json` (default) or `raw` |

## Examples

### GET request

```bash
kongctl api /v3/portals
```

### POST request

```bash
kongctl api /v3/apis -X POST -d '{
  "name": "my-api",
  "displayName": "My API"
}'
```

### PUT request

```bash
kongctl api /v3/apis/my-api -X PUT -d '{
  "displayName": "Updated API Name"
}'
```

### DELETE request

```bash
kongctl api /v3/portals/my-portal -X DELETE
```

### Custom headers

```bash
kongctl api /v3/portals -H "X-Custom-Header: value"
```

### Different region

```bash
kongctl api /v3/portals --region eu
```

## API paths

Common {{site.konnect_short_name}} API paths:

| Path | Description |
|------|-------------|
| `/v3/portals` | Developer portals |
| `/v3/apis` | API specifications |
| `/v3/control-planes` | Control planes |
| `/v3/auth-strategies` | Application auth strategies |

For complete API documentation, see the [{{site.konnect_short_name}} API reference](/konnect-api/).

## Authentication

The command uses your current authentication:

```bash
# After logging in
kongctl login

# API calls use the stored token
kongctl api /v3/portals
```

Or with a personal access token:

```bash
kongctl api /v3/portals --pat "kpat_your-token"
```

## Output

Default JSON output is pretty-printed:
```json
{
  "data": [
    {
      "id": "550e8400-e29b-41d4-a716-446655440000",
      "name": "my-portal",
      "displayName": "My Portal"
    }
  ]
}
```

For raw output:
```bash
kongctl api /v3/portals --output raw
```

## Use with jq

Combine with jq for advanced filtering:

```bash
kongctl api /v3/apis | jq '.data[] | select(.name == "my-api")'
```

## When to use api vs other commands

| Use Case | Recommended Command |
|----------|---------------------|
| List resources | `kongctl get apis` |
| Declarative management | `kongctl apply` |
| Custom API calls | `kongctl api` |
| APIs not in kongctl yet | `kongctl api` |
| Debugging | `kongctl api` |

## Command usage

{% include_cached kongctl/help/api.md %}

## Related resources

* [{{site.konnect_short_name}} API reference](/konnect-api/)
* [kongctl get](/kongctl/commands/get/)
* [Authentication guide](/kongctl/authentication/)
