---
title: Get started with kongctl
content_type: how_to
description: Learn how to install kongctl and use it to manage Kong Konnect resources.
tldr:
  q: What will I learn?
  a: Install kongctl, authenticate to Konnect, and learn basic resource management and declarative workflows.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - cli
  - get-started
  - declarative-config
breadcrumbs:
  - /kongctl/
related_resources:
  - text: kongctl on GitHub
    url: https://github.com/Kong/kongctl
  - text: Declarative configuration guide
    url: /kongctl/declarative/
---

This guide walks you through installing kongctl and using it to manage {{site.konnect_short_name}} resources.

## Prerequisites

* A {{site.konnect_short_name}} account. If you don't have one, [sign up for free](https://konghq.com/products/kong-konnect/register).
* Command-line access on macOS, Linux, or Windows

## Install kongctl

Choose your platform and install kongctl:

{% navtabs %}
{% navtab macOS %}
Install using Homebrew:

```bash
brew install --cask kong/kongctl/kongctl
```

Verify the installation:

```bash
kongctl version --full
```
{% endnavtab %}
{% navtab Linux %}
Download the latest binary from the [GitHub releases page](https://github.com/Kong/kongctl/releases):

```bash
# Download the binary (replace 0.3.8 with the latest version)
curl -sL https://github.com/Kong/kongctl/releases/download/v0.3.8/kongctl_0.3.8_linux_amd64.tar.gz -o kongctl.tar.gz

# Extract the archive
tar -xzf kongctl.tar.gz

# Move the binary to your PATH
sudo mv kongctl /usr/local/bin/

# Verify the installation
kongctl version --full
```
{% endnavtab %}
{% navtab Windows %}
1. Navigate to the [kongctl releases page](https://github.com/Kong/kongctl/releases)
2. Download the Windows binary (e.g., `kongctl_0.3.8_windows_amd64.zip`)
3. Extract the ZIP archive
4. Move `kongctl.exe` to a directory in your PATH
5. Verify the installation:

```powershell
kongctl version --full
```
{% endnavtab %}
{% endnavtabs %}

## Authenticate to {{site.konnect_short_name}}

kongctl requires authentication to interact with {{site.konnect_short_name}}. The recommended method is browser-based device flow:

```bash
kongctl login
```

This command opens your browser and prompts you to authorize kongctl. After authorization, your credentials are stored locally at `~/.config/kongctl/config.yaml` and refreshed automatically.

Verify your authentication:

```bash
kongctl get me
```

You should see your {{site.konnect_short_name}} user information.

## View resources

List all APIs in your organization:

```bash
kongctl get apis
```

Get details for a specific API:

```bash
kongctl get api <api-name>
```

View output in JSON format:

```bash
kongctl get apis --output json
```

Filter results using built-in jq expressions:

```bash
kongctl get apis --output json --jq '.[] | select(.name == "my-api")'
```

## Use the interactive terminal UI

Launch the interactive terminal UI to explore resources visually:

```bash
kongctl view
```

Navigate using keyboard shortcuts:
- Arrow keys to move between items
- Enter to view details
- Tab to switch panels
- q to quit

## Manage resources declaratively

kongctl supports managing {{site.konnect_short_name}} infrastructure as code using declarative YAML configuration.

### Create a configuration file

Create a file named `my-portal.yaml`:

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: my-developer-portal
spec:
  displayName: "Developer Portal"
  description: "API documentation for developers"
  isPublic: true
```

### Preview changes with plan

Generate a plan to preview what changes will be made:

```bash
kongctl plan -f my-portal.yaml
```

This shows you what resources will be created, updated, or deleted without actually making changes.

### Apply changes

Apply the configuration to create or update resources:

```bash
kongctl apply -f my-portal.yaml
```

This creates or updates resources but does not delete anything not in the file.

### View differences

After making changes to your configuration file, view the differences:

```bash
kongctl diff -f my-portal.yaml
```

### Sync to exact state

To make {{site.konnect_short_name}} match your configuration exactly (including deletions):

```bash
kongctl sync -f my-portal.yaml
```

{:.warning}
> **Warning**: The `sync` command will delete resources in {{site.konnect_short_name}} that are not defined in your configuration files. Use with caution.

### Export current state

Dump your current {{site.konnect_short_name}} state to a file:

```bash
kongctl dump --output-file current-state.yaml
```

This is useful for:
- Creating backups
- Migrating configurations
- Adopting existing resources into declarative management

## Use kongctl in CI/CD

For automated workflows, use personal access tokens instead of device flow:

1. Create a personal access token in {{site.konnect_short_name}}
2. Set the environment variable:

```bash
export KONGCTL_DEFAULT_KONNECT_PAT="your-token-here"
```

3. Use plan artifacts in pull requests:

```bash
# Generate plan
kongctl plan -f config.yaml --output-file plan.json

# Review plan in PR, then apply after approval
kongctl apply --plan plan.json
```

See the [CI/CD integration guide](/kongctl/declarative/ci-cd/) for detailed examples.

## Next steps

* Learn more about [declarative configuration](/kongctl/declarative/)
* Explore [command reference](/kongctl/commands/)
* Review [authentication methods](/kongctl/authentication/)
* Check out [examples on GitHub](https://github.com/Kong/kongctl/tree/main/docs/examples)
