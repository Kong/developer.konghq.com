---
title: kongctl commands
content_type: reference
description: Overview of kongctl commands for managing Kong Konnect resources.
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
---

kongctl provides commands for managing {{site.konnect_short_name}} resources through imperative operations, declarative configuration, and interactive exploration.

## Command structure

Commands follow this pattern:

```bash
kongctl <verb> <resource-type> [resource-name] [flags]
```

For example:
```bash
kongctl get apis
kongctl get api my-api
kongctl delete api my-api
```

## Authentication commands

| Command | Description |
|---------|-------------|
| [`kongctl login`](/kongctl/commands/login/) | Authenticate using browser-based device flow |
| `kongctl logout` | Clear saved credentials |

## Resource commands

| Command | Description |
|---------|-------------|
| [`kongctl get`](/kongctl/commands/get/) | Retrieve and list resources |
| `kongctl create` | Create a new resource |
| `kongctl update` | Update an existing resource |
| `kongctl delete` | Delete a resource |

## Declarative commands

| Command | Description |
|---------|-------------|
| [`kongctl plan`](/kongctl/commands/plan/) | Generate a plan to preview changes |
| [`kongctl apply`](/kongctl/commands/apply/) | Apply configuration (create/update only) |
| [`kongctl sync`](/kongctl/commands/sync/) | Sync to exact state (includes deletions) |
| [`kongctl diff`](/kongctl/commands/diff/) | Show differences between local and remote state |
| [`kongctl dump`](/kongctl/commands/dump/) | Export current state to YAML |
| [`kongctl adopt`](/kongctl/commands/adopt/) | Adopt existing resources for declarative management |

## Interactive commands

| Command | Description |
|---------|-------------|
| [`kongctl view`](/kongctl/commands/view/) | Launch interactive terminal UI |
| `kongctl kai` | Interact with Kai AI assistant |

## API commands

| Command | Description |
|---------|-------------|
| [`kongctl api`](/kongctl/commands/api/) | Call {{site.konnect_short_name}} APIs directly |

## Supported resource types

kongctl can manage the following {{site.konnect_short_name}} resources:

* **APIs**: API specifications, versions, and publications
* **Portals**: Developer portals, pages, and customizations
* **Application Auth Strategies**: Authentication configuration for applications
* **Control Planes**: {{site.base_gateway}} control plane management
* **Gateway Services**: Gateway service configuration

For the complete list of supported resources and their fields, see [Supported Resources](/kongctl/reference/supported-resources/).

## Global flags

These flags work with all commands:

| Flag | Description |
|------|-------------|
| `--output` | Output format: `table`, `json`, or `yaml` |
| `--pat` | Personal access token for authentication |
| `--region` | {{site.konnect_short_name}} region (us, eu, au) |
| `--help` | Display help for any command |
| `--version` | Display version information |

## Examples

List all APIs with JSON output:
```bash
kongctl get apis --output json
```

Filter results using jq:
```bash
kongctl get apis --output json --jq '.[] | select(.name == "my-api")'
```

Use a personal access token:
```bash
kongctl get apis --pat "kpat_your-token-here"
```

Get help for a specific command:
```bash
kongctl plan --help
```

## Related resources

* [Get started with kongctl](/kongctl/get-started/)
* [Declarative configuration](/kongctl/declarative/)
* [Environment variables](/kongctl/reference/environment-variables/)
