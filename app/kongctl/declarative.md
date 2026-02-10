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
next_steps:
  - text: Example declarative configurations
    url: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative
  - text: Learn about kongctl authorization options
    url: /kongctl/authentication/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: Using kongctl and deck for full API platform management
    url: /kongctl/kongctl-and-deck/
  - text: View the {{site.konnect_short_name}} API reference
    url: /konnect-api/
---

{:.success}
> **New to kongctl?** This document provides an extensive reference to declarative management with kongctl. For a shorter getting started experience, see 
the [Get started with kongctl](/kongctl/get-started/) guide to quickly learn basic usage and resource management.

kongctl's declarative management feature enables you to manage {{site.konnect_short_name}} resources using simple YAML configuration files and a stateless CLI tool. 
This approach provides version control, automation, and predictable deployments through a plan-based workflow.


Declarative configuration with kongctl means you describe the **desired state** of your {{site.konnect_short_name}} resources in 
static YAML files, and kongctl calculates and executes the changes needed to reach the desired state. 

The following are key principles of declarative configuration with kongctl:

- **Configuration input**: Express your desired state in a YAML format that can be split and saved into multiple files and directories for modularity.
- **Plan-based workflow**: Generate plan artifacts that represent the changes needed, review them, and apply them later.
- **Stateless operation**: kongctl queries the live {{site.konnect_short_name}} state instead of maintaining a separate state file.
- **Namespace ownership**: Use namespaces to group resources between teams and environments.

## Core concepts

### Configuration input files

kongctl declarative configuration uses YAML files to describe your desired state. These files define resources and their properties using a simple, structured format.

The following is an example of the basic structure:

```yaml
portals: 
  - ref: developer-portal
    name: "developer-portal"
    display_name: "Developer Portal"
  - ref: portal-num-two
    name: "another portal"
    display_name: "Amazing Dev Portal"

apis:
  - ref: users-api
    name: "Users API"
```

Different resources and resource types can be defined in a single file, or split across multiple files:

```
project/
├── portals.yaml
├── apis.yaml
└── auth-strategies.yaml
```

### Resource identity

Resources in {{site.konnect_short_name}} and kongctl have multiple identifiers:

* `ref`: kongctl specific identifier that's unique across all resources in a set of input configuration files. Used to identify and reference resources _within your configuration_.
* `id`: {{site.konnect_short_name}} assigned UUID. Not all {{site.konnect_short_name}} resources support `id` fields and it isn't typically stored in declarative configuration files.
* `name`: {{site.konnect_short_name}} resources _often_ have a name field, which is usually unique across an organization, but may not be depending on the resource type.

```yaml
application_auth_strategies:
  - ref: oauth-strategy              # Identifies resource in configuration only
    name: "OAuth 2.0 Strategy"       # {{site.konnect_short_name}} 'name' field value
                                     # 'id' fields are assigned by {{site.konnect_short_name}} but not stored in configuration
```

### Plan-based approach

A plan is a JSON object that defines the steps needed to move resources from their current state to the desired state and are central to the 
kongctl approach to declarative configuration. Planning happens either implicitly or explicitly when using the 
declarative configuration commands.

**Implicit planning** (generate plan and execute immediately):

```bash
kongctl apply -f config.yaml
```

**Explicit planning** (generate plan and pass to a later _execution_ operation):

```bash
# Phase 1: Generate plan
kongctl plan -f config.yaml --output-file plan.json

# Phase 2: Review and apply later
kongctl apply --plan plan.json
```

You can use plan artifacts for the following use cases:
* **Audit trail**: Plans provide an audit record of proposed changes independent of the input or current state.
* **Review process**: Share and review plans before execution.
* **Deferred execution**: Generate plans in CI, attach to pull requests, and apply after approval.
* **Compliance**: Document exactly what changes were planned along with the execution logs.

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
so that kongctl will manage the resource going forward.

## kongctl metadata

In the input configuration, you can provide some kongctl specific metadata values that affect the behavior of the 
declarative system. You can provide this `kongctl` section on individual resources or at the configuration file level. 

These values are stored on resources via the {{site.konnect_short_name}} [resource labels](/konnect-platform/konnect-labels/),
so only resources that support labels are supported. In general, only parent resources support labels and child 
resources inherit the values from their parents.

### Namespace 

The `namespace` field allows you to define ownership and isolation of resources. You may choose to assign any
`namespace` you choose, but common patterns would be teams (finance, engineering) or environments (prod, dev).

**Child resources** automatically inherit the namespace from their parent.

```yaml
apis:
  - ref: billing-api
    name: "Billing API"
    kongctl:
      namespace: finance-team
```

### Protected resources

When a resource is marked `protected: true`, the kongctl declarative planner will not allow planning of
updates or deletes to those resources. To update or delete these resources, change the
resource from `protected: true` to `protected: false`. Once you update this, then you are allowed to make subsequent changes.

```yaml
portals:
  - ref: production-portal
    name: "Production Portal"
    kongctl:
      protected: true  # Cannot be deleted
```

### File-level defaults

A the file level, you can use `_defaults` to set default metadata for all resources in a file:

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
      # Overrides both defaults
      namespace: qa-team
      protected: false
```

### kongctl metadata precedence

The following table describes which namespace metadata takes precedence:

<!--vale off-->
{% table %}
columns:
  - title: File Default
    key: file_default
  - title: Resource Value
    key: resource_value
  - title: Result
    key: result
  - title: Notes
    key: notes
rows:
  - file_default: Not set
    resource_value: Not set
    result: "`default`"
    notes: Default
  - file_default: Not set
    resource_value: team-a
    result: "`team-a`"
    notes: Resource explicit
  - file_default: team-b
    resource_value: Not set
    result: "`team-b`"
    notes: Inherits default
  - file_default: team-b
    resource_value: team-a
    result: "`team-a`"
    notes: Resource overrides
{% endtable %}
<!--vale on-->


The following table describes which protected field metadata takes precedence:

<!--vale off-->
{% table %}
columns:
  - title: File Default
    key: file_default
  - title: Resource Value
    key: resource_value
  - title: Result
    key: result
  - title: Notes
    key: notes
rows:
  - file_default: Not set
    resource_value: Not set
    result: "`false`"
    notes: Default
  - file_default: Not set
    resource_value: true
    result: "`true`"
    notes: Resource explicit
  - file_default: true
    resource_value: Not set
    result: "`true`"
    notes: Inherits default
  - file_default: true
    resource_value: false
    result: "`false`"
    notes: Resource overrides
{% endtable %}
<!--vale on-->

### namespace enforcement flags

The following flags allow further control over namespaces when running the declarative commands:

```bash
# Require all resources to declare a namespace
kongctl plan -f config.yaml --require-any-namespace

# Restrict to specific namespaces
kongctl plan -f config.yaml --require-namespace=team-a,team-b
```

### Adopting existing resources

Use `kongctl adopt` to bring {{site.konnect_short_name}} resources created outside the declarative system into it.

```bash
# Adopt a portal
kongctl adopt portal my-portal --namespace team-alpha

# Adopt a control plane
kongctl adopt control-plane <cp-id> --namespace platform
```

This adds the namespace label without modifying other fields. After adoption, add the resource to your configuration files.

### Stateless operation

Unlike other declarative solutions, kongctl doesn't maintain any local state storage to complete it's planning and execution. Instead, it does the following:

1. You provide the desired state (YAML files).
2. kongctl queries the current state from {{site.konnect_short_name}}.
3. kongctl calculates the difference.
4. kongctl applies the changes.

This means:
* No state file to manage or lock
* Always reflects the live {{site.konnect_short_name}} state
* Can run from anywhere with the same configuration
* Multiple people can use the same configuration files

{:.warning}
> **Caution**: Be careful with concurrent operations on the same resources. Use namespace isolation to avoid conflicts.

## YAML tags

YAML tags act as pre-processors, allowing you to load content from external files and cross-reference resources.

### Loading file content

Use `!file` to load entire file contents. This is useful for resources that have large content stored in files
like OpenAPI specifications or Dev Portal pages and documentation.

```yaml
apis:
  - ref: users-api
    name: "Users API"
    description: !file ./docs/api-description.md
    versions:
      - ref: v1
        spec: !file ./specs/users-v1.yaml
```

### Extracting values from structured files

When the input file for `!file` is a structured file (JSON or YAML), you can
extract specific values using the `!file <path>#field` notation:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/openapi.yaml#info.title
    description: !file ./specs/openapi.yaml#info.description
    versions:
      - ref: v1
        spec: !file ./specs/openapi.yaml
```

### Referencing other resources

Use the `!ref` YAML tag to reference values from other declared resources:

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

Path resolution is when all file paths are relative to the directory containing the configuration file.

Path resolution has the following security features:
* Absolute paths are blocked
* Relative paths with `..` must stay within the base directory boundary
* Files limited to 10MB
* Default base directory is the parent of each `-f` source file
* Override with `--base-dir` flag

```yaml
# Allowed (within base directory)
description: !file ./docs/description.txt
spec: !file ../shared/openapi.yaml

# Blocked (absolute path)
config: !file /etc/passwd

# Blocked (outside base directory)
secret: !file ../../../sensitive.yaml
```

Files are cached during execution for performance:

```yaml
apis:
  - ref: api-1
    name: !file ./common.yaml#api.name        # Loaded and cached
    description: !file ./common.yaml#api.desc # Uses cache
  - ref: api-2
    team: !file ./common.yaml#team.name       # Uses cache
```

## External resources

The external resources feature allows you to reference {{site.konnect_short_name}} resources
managed outside of kongctl. Some {{site.konnect_short_name}} resources reference others, so this
can be useful for cross-team references, or references to resources created by different management techniques or 
technologies.

The following are key characteristics of external resources:
* **Cannot declare kongctl metadata**: External resources don't support `kongctl.namespace` or `kongctl.protected`
* **Not included in sync planning**: External namespaces don't affect deletion calculations
* **Used for references**: Child resources can reference external parents

### Basic syntax

The resource requires a `ref` field, which is how it is further referenced by dependent resources. 
The resource is denoted as external by marking it with an `_external` key. Below the `_external` key,
you define a _selector_ which will query the organization for resources matching given fields.

```yaml
portals:
  - ref: shared-developer-portal
    _external:
      selector:
        matchFields:
          name: "Shared Developer Portal"
```

### API Publication and shared portal example

The following example shows how you can use external resources to manage an API that is published to a Dev Portal that is owned by the platform team:
```yaml
# External portal managed by platform team
portals:
  - ref: platform-portal
    _external:
      selector:
        matchLabels:
          team: platform

# Your API published to the external portal
api_publications:
  - ref: my-api-pub
    api: my-api
    portal_id: !ref platform-portal#id 
```

## Best practices

Use namespaces for isolation. Separate resources by team or environment:

```yaml
_defaults:
  kongctl:
    namespace: team-alpha

apis:
  - ref: team-api
    name: "Team API"
    # Automatically in team-alpha namespace
```

Protect critical resources:

```yaml
apis:
  - ref: production-api
    name: "Production API"
    kongctl:
      namespace: production
      protected: true  # Prevents accidental deletion
```

Review plans before applying. Use the two-phase workflow for production:

```bash
# Generate plan
kongctl plan -f config.yaml --output-file plan.json

# Review in pull request or approval process
kongctl diff --plan plan.json

# Apply after approval
kongctl apply --plan plan.json
```

## Examples

For complete working examples, see the [kongctl examples directory](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative).

## Troubleshooting

### Authentication failures

If authentication fails, do the following:

If authentication fails, do the following:

1. Verify authentication:
    ```sh
    kongctl get me
    ```
1. Re-authenticate if needed:
    ```sh
    kongctl login
    ```

### Plan generation failures

If plan generation fails, do the following:
* Validate YAML syntax
* Check that file paths are correct and in the base directory
* Verify network connectivity to {{site.konnect_short_name}}

### Apply failures

If the configuration fails while you are applying it, do the following:
* Review the plan for conflicts
* Check for protected resources blocking deletion
* Verify all referenced resources exist

### File loading errors

If you are loading a file and get the `Error: failed to process file tag: file not found`, do the following:
* Verify that the file path is correct and relative to the config file.
* Check that the file exists and is in the base directory.
* Ensure the file size is under 10MB.

### Field validation errors

kongctl uses strict validation:

```yaml
portals:
  - ref: my-portal
    labels:
      team: platform
```

Enable debug logging:

```bash
kongctl apply -f config.yaml --log-level debug
```
