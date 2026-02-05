---
title: Get started with kongctl
description: Learn how to use kongctl to manage {{site.konnect_product_name}} resources
content_type: how_to
permalink: /kongctl/get-started/
breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration guide
    url: /kongctl/declarative/

products:
  - konnect

works_on:
  - konnect

tags:
  - cli
  - get-started
  - declarative-config

tldr:
  q: What will I learn?
  a: |
    This guide teaches you how to use kongctl to manage {{site.konnect_short_name}} resources.
    You'll authenticate, view resources, and use declarative configuration to manage infrastructure as code.

tools:
  - kongctl

automated_tests: false
---

## Authenticate to {{site.konnect_short_name}}

Before you can manage resources, authenticate to {{site.konnect_short_name}} using the browser-based device flow:

```bash
kongctl login
```

This opens your browser and prompts you to authorize kongctl. After successful authorization, verify your authentication:

```bash
kongctl get me
```

You should see your {{site.konnect_short_name}} user information displayed.

## View existing resources

List all developer portals in your organization:

```bash
kongctl get portals
```

List all APIs:

```bash
kongctl get apis
```

Get details about a specific resource with JSON output:

```bash
kongctl get portals --output json
```

## Use the interactive terminal UI

Launch the interactive terminal UI to explore resources visually:

```bash
kongctl view
```

Navigate using arrow keys, press Enter to view details, and press `q` to quit.

## Manage resources declaratively

kongctl supports infrastructure as code using declarative YAML files. Create a file named `my-portal.yaml`:

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: developer-portal
spec:
  displayName: "Developer Portal"
  description: "API documentation for developers"
  isPublic: true
```

### Preview changes with plan

Before applying changes, preview what will happen:

```bash
kongctl plan -f my-portal.yaml
```

You'll see output showing what resources will be created:

```
Plan: 1 to create, 0 to update, 0 to delete

+ Portal: developer-portal
  └─ Will be created
```

### Apply the configuration

Apply the configuration to create the portal:

```bash
kongctl apply -f my-portal.yaml
```

Verify the portal was created:

```bash
kongctl get portal developer-portal
```

### View differences

Edit your `my-portal.yaml` file and change the description to something new. Then view the differences:

```bash
kongctl diff -f my-portal.yaml
```

You'll see the changes highlighted:

```
~ Portal: developer-portal
  ~ spec.description
    - "API documentation for developers"
    + "Your new description"
```

Apply the update:

```bash
kongctl apply -f my-portal.yaml
```

## Export current state

At any point, you can export your entire {{site.konnect_short_name}} configuration to a file:

```bash
kongctl dump --output-file current-state.yaml
```

This creates a snapshot of all your resources that you can:
- Use as a backup
- Edit and re-apply
- Commit to version control

## Manage multiple resources

Create a file named `infrastructure.yaml` with multiple resources:

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: developer-portal
spec:
  displayName: "Developer Portal"
  description: "External API documentation"
  isPublic: true
---
apiVersion: v1
kind: API
metadata:
  name: users-api
spec:
  displayName: "Users API"
  description: "User management REST API"
  version: "1.0.0"
  labels:
    team: platform
    environment: production
```

Apply all resources at once:

```bash
kongctl apply -f infrastructure.yaml
```

## Use sync for exact state matching

The `apply` command creates and updates resources but doesn't delete anything. To make {{site.konnect_short_name}} match your configuration exactly (including deletions), use `sync`:

{:.warning}
> **Warning**: `sync` will delete resources in {{site.konnect_short_name}} that are not in your configuration files.

Preview what sync will do:

```bash
kongctl plan -f infrastructure.yaml --mode sync
```

Then sync to the exact state:

```bash
kongctl sync -f infrastructure.yaml
```

## Filter and query resources

Use the built-in jq filtering to query resources:

```bash
kongctl get apis --output json --jq '.[] | select(.labels.team == "platform")'
```

Get just the names of all portals:

```bash
kongctl get portals --output json --jq '.[].name'
```

## Call APIs directly

For advanced use cases, call {{site.konnect_short_name}} APIs directly:

```bash
kongctl api /v3/portals
```

This uses your authenticated session and outputs the raw API response.

## Next steps

You've now learned the basics of kongctl! Here's what to explore next:

* [Declarative configuration guide](/kongctl/declarative/) - Learn infrastructure as code in depth
* [CI/CD integration](/kongctl/declarative/ci-cd/) - Automate deployments with GitHub Actions, GitLab CI, and more
* [Authentication guide](/kongctl/authentication/) - Set up personal access tokens for automation

Congratulations! You just went from zero to managing {{site.konnect_short_name}} resources with kongctl.
