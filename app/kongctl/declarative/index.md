---
title: Declarative configuration with kongctl
content_type: concept
description: Learn how to manage Kong Konnect infrastructure as code using declarative YAML configuration.
products:
  - konnect
tools:
  - kongctl
works_on:
  - konnect
tags:
  - declarative-config
  - automation
breadcrumbs:
  - /kongctl/
related_resources:
  - text: CI/CD integration guide
    url: /kongctl/declarative/ci-cd/
  - text: Get started with kongctl
    url: /kongctl/get-started/
---

kongctl enables you to manage {{site.konnect_short_name}} infrastructure as code using declarative YAML configuration files. This approach provides version control, automation, and predictable deployments.

## What is declarative configuration?

Declarative configuration means you describe the **desired state** of your infrastructure in files, and kongctl makes {{site.konnect_short_name}} match that state. You don't write imperative commands; you declare what you want.

### Imperative vs declarative

**Imperative** (commands that modify state):
```bash
kongctl create api my-api --display-name "My API"
kongctl update api my-api --description "Updated"
```

**Declarative** (describe desired state):
```yaml
# my-api.yaml
apiVersion: v1
kind: API
metadata:
  name: my-api
spec:
  displayName: "My API"
  description: "Updated"
```

```bash
kongctl apply -f my-api.yaml
```

## Benefits

### Version control
Store configuration in Git for:
* Change history and audit trails
* Code reviews via pull requests
* Rollback capabilities
* Team collaboration

### Automation
Enable GitOps workflows:
* Automatic deployments on merge
* Consistent environments
* Reduced manual errors
* Faster iteration

### Predictability
Preview changes before applying:
* Generate plans for review
* Catch errors early
* Understand impact
* Increase confidence

### Reusability
Share and template configurations:
* Multi-environment deployments
* Standardized patterns
* Quick environment setup
* Disaster recovery

## Configuration file format

kongctl uses YAML files with this structure:

```yaml
apiVersion: v1
kind: <ResourceType>
metadata:
  name: <resource-name>
spec:
  <resource-fields>
```

### Multiple resources

Define multiple resources in one file using `---`:

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: developer-portal
spec:
  displayName: "Developer Portal"
  isPublic: true
---
apiVersion: v1
kind: API
metadata:
  name: users-api
spec:
  displayName: "Users API"
  version: "1.0.0"
```

## Basic workflow

### 1. Create configuration files

Create YAML files describing your desired state:

```yaml
# config/portal.yaml
apiVersion: v1
kind: Portal
metadata:
  name: my-portal
spec:
  displayName: "My Developer Portal"
  description: "API documentation for developers"
  isPublic: true
```

### 2. Preview changes

Generate a plan to see what will change:

```bash
kongctl plan -f config/
```

Output shows creates, updates, and deletes:
```
Plan: 1 to create, 0 to update, 0 to delete

+ Portal: my-portal
  └─ Will be created
```

### 3. Apply changes

Apply the configuration:

```bash
kongctl apply -f config/
```

Or sync for exact state matching (including deletions):

```bash
kongctl sync -f config/
```

### 4. Iterate

Make changes to files and repeat:

```bash
# Edit files
vim config/portal.yaml

# Preview
kongctl diff -f config/

# Apply
kongctl apply -f config/
```

## Core commands

| Command | Description | Deletions? |
|---------|-------------|------------|
| `plan` | Preview changes without applying | Shows only |
| `apply` | Create and update resources | No |
| `sync` | Match exact state | Yes ⚠️ |
| `diff` | Show differences | Shows only |
| `dump` | Export current state | N/A |

## Supported resources

kongctl currently supports declarative management of:

* **APIs**: API specifications, versions, and publications
* **Portals**: Developer portals, pages, and customizations
* **Application Auth Strategies**: Authentication configuration
* **Control Planes**: {{site.base_gateway}} control plane management
* **Gateway Services**: Gateway service configuration

For detailed resource schemas, see [Supported Resources](/kongctl/reference/supported-resources/).

## Organization strategies

### Single file
Good for simple setups:
```
config.yaml
```

### Multiple files by type
Organize by resource type:
```
config/
├── apis.yaml
├── portals.yaml
└── control-planes.yaml
```

### Multiple files by environment
Separate configurations per environment:
```
environments/
├── dev/
│   ├── apis.yaml
│   └── portals.yaml
└── prod/
    ├── apis.yaml
    └── portals.yaml
```

### Hierarchical
Complex deployments:
```
config/
├── base/
│   └── common.yaml
├── staging/
│   └── overrides.yaml
└── production/
    └── overrides.yaml
```

## Plan-based workflows

For production deployments, use plan artifacts:

```bash
# Generate and save plan
kongctl plan -f config/ --output-file plan.json

# Review plan (in PR, approval process, etc.)
cat plan.json

# Apply exact plan that was reviewed
kongctl apply --plan plan.json
```

This ensures the changes you reviewed are exactly what gets applied.

## State management

kongctl is **stateless** - it doesn't maintain a separate state file. Instead:

1. You provide desired state (YAML files)
2. kongctl queries current state ({{site.konnect_short_name}} APIs)
3. kongctl calculates differences
4. kongctl applies changes

This means:
* No state file to manage or lock
* Always reflects live state
* Can run from anywhere with same config
* Multiple people can use same config

{:.note}
> **Note**: Because kongctl is stateless, be careful when running concurrent operations on the same resources. Use namespace isolation or separate configurations to avoid conflicts.

## Best practices

### Store in version control
Always commit configuration to Git:
```bash
git add config/
git commit -m "Add developer portal configuration"
git push
```

### Use descriptive names
Choose clear, consistent names:
```yaml
# Good
name: production-api-portal

# Avoid
name: portal1
```

### Add comments
Document why, not what:
```yaml
# Docs portal for external developers
# Updated 2025-01-30 for new auth strategy
kind: Portal
metadata:
  name: external-docs
```

### Preview before applying
Always check changes first:
```bash
kongctl diff -f config/
# or
kongctl plan -f config/
```

### Start with dump
Adopt existing resources:
```bash
kongctl dump --output-file current.yaml
# Edit and organize
kongctl apply -f current.yaml
```

## Examples

### Create a developer portal

```yaml
apiVersion: v1
kind: Portal
metadata:
  name: developer-portal
spec:
  displayName: "Developer Portal"
  description: "API documentation for external developers"
  isPublic: true
  customDomain: "developers.example.com"
```

### Define an API

```yaml
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

### Configure auth strategy

```yaml
apiVersion: v1
kind: ApplicationAuthStrategy
metadata:
  name: oauth2-strategy
spec:
  displayName: "OAuth 2.0 Authentication"
  authType: oauth2
  scopes:
    - read:apis
    - write:apis
```

## Next steps

* Learn about [CI/CD integration](/kongctl/declarative/ci-cd/)
* Review [supported resources](/kongctl/reference/supported-resources/)
* See [example configurations](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative)
