---
title: Declarative configuration with kongctl

description: Learn how to manage {{site.konnect_product_name}} infrastructure as code using declarative YAML configuration.

content_type: reference
layout: reference

beta: true

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: CI/CD integration guide
    url: /kongctl/ci-cd/
  - text: Get started with kongctl
    url: /kongctl/get-started/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

kongctl's declarative management feature enables you to manage {{site.konnect_short_name}} resources using simple YAML configuration files and a stateless CLI tool. 
This approach provides version control, automation, and predictable deployments through a plan-based workflow.

{:.info}
> **New to kongctl?** Start with the [Get started with kongctl](/kongctl/get-started/) guide to learn authentication and basic usage.

## Overview

Declarative configuration with kongctl means you describe the **desired state** of your {{site.konnect_short_name}} resources in 
static YAML files, and kongctl calculates and executes the changes needed to reach the desired state.

### Key principles

- **Configuration input**: Express your desired state in a simple YAML format which can be split and saved into multiple files and directories for modularity
- **Plan-based workflow**: Generate plan artifacts that represent the changes needed, review them, and apply them later
- **Stateless operation**: kongctl queries live {{site.konnect_short_name}} state instead of maintaining a separate state file
- **Namespace ownership**: Use namespaces to group resources between teams and environments

## Core concepts

### Resource identity

Resources in {{site.konnect_short_name}} and kongctl will have multiple identifiers:

* `ref`: kongctl specific identifier unique across all resource in a set of input configuration files. Used to identify and reference resources _within your configuration_.
* `id`: {{site.konnect_short_name}} assigned UUID. Not all {{site.konnect_short_name}} resources support `id` fields and it is not typically stored in declarative configuration files.
* `name`: {{site.konnect_short_name}} resources _often_ have a name field which is usually unique across an organization but may not be depending on the resource type.

```yaml
application_auth_strategies:
  - ref: oauth-strategy              # Identifies resource in configuration
    name: "OAuth 2.0 Strategy"       # Name assigned in {{site.konnect_short_name}}
```

### Plan based approach

Plans are central to kongctl's approach. A plan is a JSON object that defines the steps needed to move resources from their current state to the desired state.
Planning happens either implicitly or explicitly when using the declarative configuration commands.

**Implicit planning** (generate plan and execute immediately):

```bash
kongctl apply -f config.yaml
```

**Explicit planning** (generate pland and pass to a later execution operation):

```bash
# Phase 1: Generate plan
kongctl plan -f config.yaml --output-file plan.json

# Phase 2: Review and apply later
kongctl apply --plan plan.json
```

#### Why use plan artifacts?

* **Audit trail**: Plans provide an auditable record of proposed changes independent of the input or current state
* **Review process**: Share and review plans before execution
* **Deferred execution**: Generate plans in CI, attach to pull requests, and apply after approval
* **Compliance**: Document exactly what changes were planned along with the execution logs

### Declarative commands

The following are the commands you use to employ kongctl declarative configuration.

#### `plan`

Generate a plan artifact storing a set of proposed changes:

```bash
# Generate apply plan (no deletions)
kongctl plan -f config.yaml --mode apply

# Generate sync plan (includes deletions)
kongctl plan -f config.yaml --mode sync --output-file plan.json
```

#### `diff`

Display human-readable preview of planned changes

```bash
# Generate a plan and print summary of prposed changes
kongctl diff -f config.yaml

# Print a summary of proposed changes from plan artifact input
kongctl diff --plan plan.json
```

#### `apply`

Create or update resources based on a set of configuration inputs or a plan artifact:

```bash
# Apply from config
kongctl apply -f config.yaml

# Apply from plan
kongctl apply --plan plan.json

# Preview without applying
kongctl apply -f config.yaml --dry-run
```

#### `sync`

Create, update, or delete resources based on a set of configuration inputs or a plan artifact:

```bash
# Preview sync changes
kongctl sync -f config.yaml --dry-run

# Sync with confirmation prompt
kongctl sync -f config.yaml

# Sync without prompt (dangerous!)
kongctl sync -f config.yaml --auto-approve
```

{:.warning}
> **Caution**: `sync` deletes resources missing from your configuration, always ensure changes are desired before executing.

#### `dump`

The `dump` command will export existing {{site.konnect_short_name}} state to files.

```bash
# Export to declarative format
kongctl dump declarative --resources=portal,api

# Export to Terraform import format
kongctl dump tf-import --resources=api --include-child-resources
```

#### `adopt`

Bring existing {{site.konnect_short_name}} resources under declarative management by adding proper labels:

```bash
# Adopt a portal by name
kongctl adopt portal my-portal --namespace team-alpha

# Adopt a control plane by ID
kongctl adopt control-plane <cp-id> --namespace platform

# Adopt an API
kongctl adopt api my-api --namespace production
```

{:.warning}
> Before adopting a resource, add it to your declarative configuration files either manually or with the help of the `dump` command
in order to manage the resource going forward.

## kongctl metadata

Within the input configuration, users can provide some kongctl specific metadata values that affects the behavior of the 
declarative system. This `kongctl` section can be provided on indivdiual resources or at the configuration file level. 

These values are stored on resources via the {{site.konnect_short_name}} [resource labels](/konnect-platform/konnect-labels/),
so only resources supporting labels are supported. In general only parent resources (defined later) support labels and child 
resources inherit the values from their parents.

### Namespace 

The `namespace` field allows the user to define ownership and isolation of resources.

```yaml
apis:
  - ref: billing-api
    name: "Billing API"
    kongctl:
      namespace: finance-team
```

### Protected resources

When a resource is marked `protected`, the kongctl declarative planner will not allow planning of
updates or deletes to those resources. In order to update or delete these resources, only changing the
resource from `protected: true` to `protected: false` is allowed before subsequent changes can be made.

```yaml
portals:
  - ref: production-portal
    name: "Production Portal"
    kongctl:
      protected: true  # Cannot be deleted
```

### File-level defaults

A the file level, you can use `_defaults` to set defaults for all resources in a file:

```yaml
_defaults:
  kongctl:
    namespace: platform-team
    protected: true

portals:
  - ref: api-portal
    name: "API Portal"
    # Inherits: namespace=platform-team, protected=true

  - ref: test-portal
    name: "Test Portal"
    kongctl:
      namespace: qa-team
      protected: false
    # Overrides both defaults
```

### kongctl metadata precedence

**Namespace behavior**:

| File Default | Resource Value | Result | Notes |
|--------------|----------------|--------|-------|
| Not set | Not set | `default` | Default |
| Not set | `team-a` | `team-a` | Resource explicit |
| `team-b` | Not set | `team-b` | Inherits default |
| `team-b` | `team-a` | `team-a` | Resource overrides |

**Protected field behavior**:

| File Default | Resource Value | Result | Notes |
|--------------|----------------|--------|-------|
| Not set | Not set | `false` | Default |
| Not set | `true` | `true` | Resource explicit |
| `true` | Not set | `true` | Inherits default |
| `true` | `false` | `false` | Resource overrides |

**Child resources** automatically inherit the namespace from their parent.

**Namespace enforcement**: Use flags to enforce namespace requirements:

```bash
# Require all resources to declare a namespace
kongctl plan -f config.yaml --require-any-namespace

# Restrict to specific namespaces
kongctl plan -f config.yaml --require-namespace=team-a,team-b
```

### Adopting existing resources

Use `kongctl adopt` to bring existing {{site.konnect_short_name}} resources under declarative management:

```bash
# Adopt a portal
kongctl adopt portal my-portal --namespace team-alpha

# Adopt a control plane
kongctl adopt control-plane <cp-id> --namespace platform
```

This adds the namespace label without modifying other fields. After adoption, add the resource to your configuration files.

### Parent and child resources

Resources are organized hierarchically:

**Parent resources** (support kongctl metadata):
* APIs
* Portals
* Application Auth Strategies
* Control Planes
* Control Plane Groups
* Event Gateways
* Catalog Services

**Child resources** (inherit namespace from parent):
* API Versions
* API Publications
* API Implementations
* API Documents
* Portal Pages
* Portal Snippets
* Portal Customizations
* Portal Custom Domains
* Gateway Services

Child resources can be defined nested under their parent or separately with a parent reference:

**Nested**:
```yaml
apis:
  - ref: users-api
    name: "Users API"
    versions:
      - ref: v1
        name: "v1.0.0"
```

**Separate**:
```yaml
apis:
  - ref: users-api
    name: "Users API"

api_versions:
  - ref: v1
    api: users-api
    name: "v1.0.0"
```

### Stateless operation

kongctl doesn't maintain a state file. Instead:

1. You provide desired state (YAML files)
2. kongctl queries current state from {{site.konnect_short_name}}
3. kongctl calculates the difference
4. kongctl applies changes

This means:
* No state file to manage or lock
* Always reflects live {{site.konnect_short_name}} state
* Can run from anywhere with the same configuration
* Multiple people can use the same configuration files

{:.warning}
> **Caution**: Be careful with concurrent operations on the same resources. Use namespace isolation to avoid conflicts.

## Configuration file format

### Basic structure

```yaml
# Optional defaults section
_defaults:
  kongctl:
    namespace: production
    protected: false

portals:
  - ref: developer-portal
    name: "developer-portal"
    display_name: "Developer Portal"
    kongctl:
      namespace: platform-prod  # Overrides default
      protected: true

apis:
  - ref: users-api
    name: "Users API"
    # Inherits namespace: production, protected: false
```

### Multiple files

Split configuration across multiple files:

```
project/
├── portals.yaml
├── apis.yaml
└── auth-strategies.yaml
```

Load all files:

```bash
kongctl apply -f project/
```

Or specify multiple files:

```bash
kongctl apply -f portals.yaml -f apis.yaml
```

## YAML tags

YAML tags act as preprocessors, allowing you to load content from external files and reference other resources.

### Loading file content

Use `!file` to load entire file contents:

```yaml
apis:
  - ref: users-api
    name: "Users API"
    description: !file ./docs/api-description.md
    versions:
      - ref: v1
        spec: !file ./specs/users-v1.yaml
```

### Extracting values from files

Extract specific values using `#` notation:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/openapi.yaml#info.title
    description: !file ./specs/openapi.yaml#info.description
    versions:
      - ref: v1
        spec: !file ./specs/openapi.yaml
```

Or using map format:

```yaml
apis:
  - ref: products-api
    name: !file
      path: ./specs/products.yaml
      extract: info.title
```

### Referencing other resources

Use `!ref` to reference values from other declared resources:

```yaml
control_planes:
  - ref: prod-us-runtime
    name: "prod-us"
    cluster_type: "CLUSTER_TYPE_K8S_INGRESS_CONTROLLER"

  - ref: shared-group
    name: "shared-group"
    cluster_type: "CLUSTER_TYPE_CONTROL_PLANE_GROUP"
    members:
      - id: !ref prod-us-runtime#id
```

### Path resolution and security

**Path resolution**: All file paths are relative to the directory containing the configuration file.

**Security features**:
* Absolute paths are blocked
* Relative paths with `..` must stay within the base directory boundary
* Files limited to 10MB
* Default base directory is the parent of each `-f` source file
* Override with `--base-dir` flag

```yaml
# ✅ Allowed (within base directory)
description: !file ./docs/description.txt
spec: !file ../shared/openapi.yaml

# ❌ Blocked (absolute path)
config: !file /etc/passwd

# ❌ Blocked (outside base directory)
secret: !file ../../../sensitive.yaml
```

**File caching**: Files are cached during execution for performance:

```yaml
apis:
  - ref: api-1
    name: !file ./common.yaml#api.name        # Loaded and cached
    description: !file ./common.yaml#api.desc # Uses cache
  - ref: api-2
    team: !file ./common.yaml#team.name       # Uses cache
```

## External resources

External resources (`_external` blocks) reference {{site.konnect_short_name}} objects managed outside of kongctl (by other teams, tools, or manual creation).

### Basic syntax

```yaml
portals:
  - ref: shared-portal
    _external:
      selector:
        matchLabels:
          team: platform
```

### Key characteristics

* **Cannot declare kongctl metadata**: External resources don't support `kongctl.namespace` or `kongctl.protected`
* **Not included in sync planning**: External namespaces don't affect deletion calculations
* **Used for references**: Child resources can reference external parents

### Selector types

**Match by labels**:
```yaml
_external:
  selector:
    matchLabels:
      environment: prod
      team: platform
```

**Match by name**:
```yaml
_external:
  selector:
    matchFields:
      name: "my-portal"
```

### Use case example

```yaml
# External portal managed by platform team
portals:
  - ref: platform-portal
    _external:
      selector:
        matchLabels:
          team: platform

# Your API published to their portal
api_publications:
  - ref: my-api-pub
    api: my-api
    portal_id: platform-portal  # References external portal
```

## Configuration organization strategies

### Single file
Good for simple setups:
```
config.yaml
```

### By resource type
```
config/
├── portals.yaml
├── apis.yaml
├── auth-strategies.yaml
└── control-planes.yaml
```

### By team namespace
```
teams/
├── team-alpha/
│   ├── apis.yaml
│   └── portals.yaml
└── team-beta/
    ├── apis.yaml
    └── services.yaml
```

### By environment
```
environments/
├── dev/
│   └── config.yaml
├── staging/
│   └── config.yaml
└── production/
    └── config.yaml
```

## Best practices

### Version control everything

Store configuration files, plans, and specifications in Git:

```bash
git add config/
git commit -m "Add API portal configuration"
git push
```

### Use namespaces for isolation

Separate resources by team or environment:

```yaml
_defaults:
  kongctl:
    namespace: team-alpha

apis:
  - ref: team-api
    name: "Team API"
    # Automatically in team-alpha namespace
```

### Protect critical resources

```yaml
apis:
  - ref: production-api
    name: "Production API"
    kongctl:
      namespace: production
      protected: true  # Prevents accidental deletion
```

### Review plans before applying

Use the two-phase workflow for production:

```bash
# Generate plan
kongctl plan -f config.yaml --output-file plan.json

# Review in pull request or approval process
kongctl diff --plan plan.json

# Apply after approval
kongctl apply --plan plan.json
```

### Use YAML tags for DRY configuration

Extract common data from OpenAPI specs:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/users.yaml#info.title
    description: !file ./specs/users.yaml#info.description
    versions:
      - ref: v1
        spec: !file ./specs/users.yaml
```

### Start with dump for existing resources

Adopt existing {{site.konnect_short_name}} resources:

```bash
# Export current state
kongctl dump declarative --output-file current.yaml

# Review and organize the output
vim current.yaml

# Apply to bring under declarative management
kongctl apply -f current.yaml
```

## Common patterns

### Multi-team setup

Each team manages their own namespace:

```yaml
# team-alpha/config.yaml
_defaults:
  kongctl:
    namespace: team-alpha

apis:
  - ref: frontend-api
    name: "Frontend API"
```

### Environment-specific configuration

Use profiles for different environments:

```bash
# Development
kongctl apply -f config.yaml --profile dev

# Production
kongctl apply -f config.yaml --profile prod
```

### Control Plane Groups

Manage control plane group membership:

```yaml
control_planes:
  - ref: prod-us
    name: "prod-us"
    cluster_type: "CLUSTER_TYPE_K8S_INGRESS_CONTROLLER"

  - ref: prod-eu
    name: "prod-eu"
    cluster_type: "CLUSTER_TYPE_K8S_INGRESS_CONTROLLER"

  - ref: prod-group
    name: "prod-group"
    cluster_type: "CLUSTER_TYPE_CONTROL_PLANE_GROUP"
    members:
      - id: !ref prod-us#id
      - id: !ref prod-eu#id
```

## Common mistakes to avoid

### Don't set kongctl metadata on child resources

❌ **Wrong**:
```yaml
apis:
  - ref: my-api
    kongctl:
      namespace: team-a
    versions:
      - ref: v1
        kongctl:          # ERROR - not supported
          protected: true
```

✅ **Correct**:
```yaml
apis:
  - ref: my-api
    kongctl:
      namespace: team-a
      protected: true
    versions:
      - ref: v1  # Inherits namespace from parent
```

### Use ref for references, not name

❌ **Wrong**:
```yaml
api_publications:
  - ref: pub1
    api: "Users API"  # Using display name
```

✅ **Correct**:
```yaml
api_publications:
  - ref: pub1
    api: users-api  # Using ref
```

### Don't forget empty namespaces are invalid

❌ **Wrong**:
```yaml
_defaults:
  kongctl:
    namespace: ""  # ERROR - empty not allowed
```

✅ **Correct**:
```yaml
_defaults:
  kongctl:
    namespace: default  # Or omit to use system default
```

## Examples

For complete working examples, see the [kongctl examples directory](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative).

Example configurations include:
* Simple portal and API setup
* Multi-environment deployments
* Control plane and gateway service configuration
* Advanced namespace isolation
* External resource references

## Troubleshooting

### Authentication failures

```bash
# Verify authentication
kongctl get me

# Re-authenticate if needed
kongctl login
```

### Plan generation failures

* Validate YAML syntax
* Check file paths are correct and within base directory
* Verify network connectivity to {{site.konnect_short_name}}

### Apply failures

* Review the plan for conflicts
* Check for protected resources blocking deletion
* Verify all referenced resources exist

### File loading errors

```
Error: failed to process file tag: file not found
```

* Verify file path is correct and relative to config file
* Check file exists and is within base directory
* Ensure file size is under 10MB

### Field validation errors

kongctl uses strict validation:

```yaml
portals:
  - ref: my-portal
    lables:  # ❌ ERROR: Unknown field. Did you mean 'labels'?
      team: platform
```

Enable debug logging:

```bash
kongctl apply -f config.yaml --log-level debug
```

## Next steps

* Learn about [CI/CD integration](/kongctl/ci-cd/)
* Review [supported resources](/kongctl/supported-resources/)
* See [example configurations](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative)
* Read the [{{site.konnect_short_name}} API reference](/konnect-api/)
