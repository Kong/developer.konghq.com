---
title: kongctl login
content_type: reference
description: Authenticate to Kong Konnect using browser-based device flow.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - authentication
  - cli
breadcrumbs:
  - /kongctl/
  - /kongctl/commands/
---

The `kongctl login` command authenticates you to {{site.konnect_short_name}} using browser-based device flow.

## Syntax

```bash
kongctl login [flags]
```

## Description

The `login` command opens your default browser and prompts you to authorize kongctl to access your {{site.konnect_short_name}} account. After successful authorization:

1. An access token is stored locally at `~/.config/kongctl/config.yaml`
2. The token is automatically refreshed when it expires
3. Subsequent commands use this stored token for authentication

This is the recommended authentication method for interactive use. For CI/CD pipelines and automation, use [personal access tokens](/kongctl/authentication/#personal-access-tokens) instead.

## Flags

| Flag | Type | Description |
|------|------|-------------|
| `--region` | string | {{site.konnect_short_name}} region: `us` (default), `eu`, or `au` |

## Examples

Login to the US region:
```bash
kongctl login
```

Login to the EU region:
```bash
kongctl login --region eu
```

Verify your authentication:
```bash
kongctl get me
```

## Configuration file

After successful login, credentials are stored in `~/.config/kongctl/config.yaml` (or `$XDG_CONFIG_HOME/kongctl/config.yaml` if set).

Example configuration:
```yaml
currentProfile: default
profiles:
  default:
    region: us
    authType: device-flow
```

## Logout

To clear your saved credentials:
```bash
kongctl logout
```

## Command usage

{% include_cached kongctl/help/login.md %}

## Related resources

* [Authentication guide](/kongctl/authentication/)
* [Personal access tokens](/kongctl/authentication/#personal-access-tokens)
* [Environment variables](/kongctl/reference/environment-variables/)
