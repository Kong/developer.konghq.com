---
title: kongctl view
content_type: reference
description: Launch interactive terminal UI to explore Kong Konnect resources.
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

The `kongctl view` command launches an interactive terminal-based user interface (TUI) for exploring {{site.konnect_short_name}} resources.

## Syntax

```bash
kongctl view [flags]
```

## Description

The `view` command provides a visual, keyboard-driven interface for browsing and inspecting {{site.konnect_short_name}} resources. This is useful for:

* Exploring your {{site.konnect_short_name}} organization visually
* Quickly navigating between related resources
* Inspecting resource details without complex commands
* Learning what resources are available

## Keyboard shortcuts

| Key | Action |
|-----|--------|
| `↑` / `↓` | Navigate up/down in lists |
| `←` / `→` | Navigate between panels |
| `Enter` | View details / Select item |
| `Tab` | Switch focus between panels |
| `Esc` | Go back / Close details |
| `q` | Quit the TUI |
| `/` | Search/filter (if available) |
| `r` | Refresh current view |

## Features

### Resource browsing

Navigate through different resource types:
* APIs
* Portals
* Control Planes
* Application Auth Strategies
* Gateway Services

### Detail view

Press `Enter` on any resource to view:
* Full resource details
* Metadata (ID, creation date, etc.)
* Relationships to other resources

### Multi-panel interface

The TUI typically shows:
* **Left panel**: Resource type list
* **Middle panel**: Resources of selected type
* **Right panel**: Selected resource details

## Examples

### Launch the TUI

```bash
kongctl view
```

### Launch with specific theme

If kongctl supports theme customization:
```bash
kongctl view --theme dark
```

## When to use view vs get

| Use Case | Command |
|----------|---------|
| Quick visual exploration | `kongctl view` |
| Scripting / automation | `kongctl get` |
| JSON/YAML output needed | `kongctl get` |
| Filtering with jq | `kongctl get` |
| Interactive browsing | `kongctl view` |
| CI/CD pipelines | `kongctl get` |

## Tips

* Use the TUI to discover resource names, then use `kongctl get <resource>` for detailed JSON output
* The TUI is read-only; use `kongctl apply` or API commands to make changes
* Exit anytime with `q`

## Command usage

{% include_cached kongctl/help/view.md %}

## Related resources

* [kongctl get](/kongctl/commands/get/)
* [Get started with kongctl](/kongctl/get-started/)
* [Supported resources reference](/kongctl/reference/supported-resources/)
