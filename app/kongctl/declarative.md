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
  # - text: CI/CD integration guide
  #   url: /kongctl/ci-cd/
  - text: Get started with kongctl
    url: /kongctl/get-started/
  - text: Supported resources
    url: /kongctl/supported-resources/
next_steps:
  - text: Example declarative configurations
    url: https://github.com/Kong/kongctl/tree/main/docs/examples/declarative
  - text: Learn about supported resources
    url: /kongctl/supported-resources/
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
static YAML files, and kongctl calculates and applies the changes needed to reach the desired state.

The following are key principles of declarative configuration with kongctl:

- **Configuration input**: Express your desired state in a YAML format that can be split and saved into multiple files and directories for modularity.
- **Plan-based workflow**: Generate plan artifacts that represent the changes needed, review them, and apply them later.
- **Stateless operation**: kongctl queries the live {{site.konnect_short_name}} state instead of maintaining a separate state file.
- **Namespace ownership**: Use namespaces to group resources between teams and environments.

To see the schemas for all supported resources, use `kongctl scaffold <resource_name>` or see the [kongctl declarative resource reference](/kongctl/supported-resources/).

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

```text
project/
├── portals.yaml
├── apis.yaml
└── auth-strategies.yaml
```

### Resource identity

Resources in {{site.konnect_short_name}} and kongctl have multiple identifiers:

* `ref`: kongctl-specific identifier that's unique across all resources in a set of input configuration files. Used to identify and reference resources _within your configuration_.
* `id`: {{site.konnect_short_name}} assigned UUID. Not all {{site.konnect_short_name}} resources support `id` fields and it isn't typically stored in declarative configuration files.
* `name`: {{site.konnect_short_name}} resources _often_ have a name field, which is usually unique across an organization, but may not be depending on the resource type.

```yaml
application_auth_strategies:
  - ref: oauth-strategy              # Identifies resource in configuration only
    name: "OAuth 2.0 Strategy"       # {{site.konnect_short_name}} 'name' field value
                                     # 'id' fields are assigned by {{site.konnect_short_name}} but not stored in configuration
```

### Plan-based approach

A plan is a JSON object that defines the steps needed to move resources from their current state to the desired state. Plans are central to the
kongctl approach to declarative configuration. Planning happens either implicitly or explicitly when using the 
declarative configuration commands.

**Implicit planning** (generate plan and apply immediately):

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

Display a human-readable preview of planned changes:

```bash
# Preview changes in apply mode (CREATE and UPDATE only)
kongctl diff -f config.yaml --mode apply

# Preview changes in sync mode (CREATE, UPDATE, and DELETE)
kongctl diff -f config.yaml --mode sync

# Preview targeted deletions only
kongctl diff -f config.yaml --mode delete

# Preview changes from a plan artifact
kongctl diff --plan plan.json
```

{:.info}
> `--mode` cannot be used with `--plan` because the mode is stored in the plan artifact. For `UPDATE` changes, the diff shows only the fields that would change.

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

# Sync from a plan artifact
kongctl sync --plan plan.json
```

{:.warning}
> **Caution**: `sync` deletes resources missing from your configuration. Always verify the changes before running.

Sync scope is determined by which keys are present in your configuration:

* **Omitted resource collections** are ignored -- `sync` does not touch those resources.
* **Explicit empty root lists** mean the desired count is zero. For example, `apis: []` deletes managed APIs in the selected namespace.
* **Parent and child collections are scoped separately.** A portal block without a `pages` key does not delete portal pages. Use `pages: []` to declare that a portal should have no pages.
* **Map-shaped child collections** use an empty object as the empty collection. For example, `email_templates: {}` means the portal should have no customized email templates.
* **Singleton child sections** follow the same key-presence rule, but `{}` and `null` are intentionally different. Omit a singleton key to ignore that child. For optional, delete-capable portal singletons such as `custom_domain`, `email_config`, and `audit_log_webhook`, an empty object (`{}`) scopes the child with a desired count of zero. `null` is rejected because sync does not infer delete semantics from null.
* **Empty child collections must be nested under a parent resource.** Root-level `api_documents: []` is rejected because it does not identify which API owns the desired zero count.

#### `dump`

The `dump` command exports existing {{site.konnect_short_name}} state to files.

```bash
# Export portals and APIs to declarative format, assigning a default namespace
kongctl dump declarative --resources=portal,api --default-namespace=team-alpha

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

# Adopt a custom dashboard by ID
kongctl adopt analytics dashboard <dashboard-id> --namespace analytics
```

{:.info}
> Dashboard names do not need to be unique in {{site.konnect_short_name}}. If more than one dashboard has the same name, adopt it by ID. If the resource already has a `KONGCTL-namespace` label, the command fails without making changes.

{:.warning}
> Before adopting a resource, add it to your declarative configuration files either manually or with the help of the `dump` command, so that kongctl manages the resource going forward.

## Supported resource types

**Parent resources** support `kongctl` metadata (`namespace` and `protected`):
* APIs
* Catalog services
* Portals
* Application auth strategies
* Control planes, including control plane groups
* Dashboards
* Event gateways

**Child resources** do not support `kongctl` metadata and inherit namespace from their parent:
* API versions
* API publications
* API implementations
* API documents
* Portal pages
* Portal snippets
* Portal customizations
* Portal custom domains
* Portal email configs
* Portal email templates
* Gateway services

Learn more about all of these resources in the [supported resource reference for kongctl](/kongctl/supported-resources/).

{:.info}
> **Notes**:
> * Portal email domains are imperative-only because the {{site.konnect_short_name}} API exposes them at the organization level without labels or namespace scoping. Use `kongctl get portal email-domains` to inspect them. Declarative management will be added when {{site.konnect_short_name}} supports namespacing or labels for these resources.
> * Portal email templates are customizable per portal. Apply mode creates or updates templates but does not delete any that already exist in {{site.konnect_short_name}}. Sync mode plans deletions for customized templates that are absent from the declarative configuration.

## Configuration structure

### Basic structure

Use `_defaults` to set default `kongctl` metadata for all resources in a file. Individual resources can override these defaults:

```yaml
_defaults:
  kongctl:
    namespace: production
    protected: false

portals:
  - ref: developer-portal
    name: "developer-portal"
    display_name: "Developer Portal"
    kongctl:
      namespace: platform-prod
      protected: true
```

### Root vs hierarchical configuration

Child resources can be defined either nested under their parent or at the root level with an explicit parent reference field. Both styles are equivalent and can be mixed across files.

**Hierarchical** (children nested under parent):

```yaml
apis:
  - ref: users-api
    name: "Users API"
    versions:
      - ref: v1
        name: "v1.0.0"
        spec: !file ./specs/users-v1.yaml
    publications:
      - ref: public
        portal: main-portal
        visibility: public
```

**Flat** (children declared at the root):

```yaml
apis:
  - ref: users-api
    name: "Users API"

api_versions:
  - ref: v1
    api: users-api
    name: "v1.0.0"
    spec: !file ./specs/users-v1.yaml

api_publications:
  - ref: public
    api: users-api
    portal: main-portal
```

### Portal identity provider migration

{:.warning}
> **Breaking change**: Portal OIDC and SAML configuration is no longer accepted under `auth_settings` or `portal_auth_settings`. Move provider-specific fields to `identity_providers` when they are nested under a portal, or to `portal_identity_providers` when declared at the root of a configuration. `auth_settings` now only supports `basic_auth_enabled`, `konnect_mapping_enabled`, and `idp_mapping_enabled`.

**Previous configuration**:

```yaml
portals:
  - ref: developer-portal
    name: "developer-portal"
    auth_settings:
      ref: portal-auth
      basic_auth_enabled: true
      konnect_mapping_enabled: false
      idp_mapping_enabled: true
      oidc_auth_enabled: true
      oidc_issuer: !env PORTAL_IDP_ISSUER_URL
      oidc_client_id: !env PORTAL_IDP_CLIENT_ID
      oidc_client_secret: !env PORTAL_IDP_CLIENT_SECRET
      oidc_scopes:
        - openid
        - profile
```

**Updated configuration**:

```yaml
portals:
  - ref: developer-portal
    name: "developer-portal"
    auth_settings:
      ref: portal-auth
      basic_auth_enabled: true
      konnect_mapping_enabled: false
      idp_mapping_enabled: true
    identity_providers:
      - ref: portal-oidc
        type: oidc
        enabled: true
        config:
          issuer_url: !env PORTAL_IDP_ISSUER_URL
          client_id: !env PORTAL_IDP_CLIENT_ID
          client_secret: !env PORTAL_IDP_CLIENT_SECRET
          scopes:
            - openid
            - profile
```

If you keep deprecated OIDC or SAML fields under `auth_settings`, kongctl will fail validation and prompt you to move that configuration to `identity_providers`.

### Control plane groups

Set a control plane's `cluster_type` to `"CLUSTER_TYPE_CONTROL_PLANE_GROUP"` to define a control plane group. Group membership is managed through the `members` array. Each member must resolve to the {{site.konnect_short_name}} ID of a non-group control plane. You can provide literal UUIDs or reference declarative control planes using `!ref`:

```yaml
control_planes:
  - ref: shared-group
    name: "shared-group"
    cluster_type: "CLUSTER_TYPE_CONTROL_PLANE_GROUP"
    members:
      - id: !ref prod-us-runtime#id
      - id: !ref prod-eu-runtime#id
```

When you apply or sync this configuration, kongctl replaces the entire membership list in {{site.konnect_short_name}} to match the `members` block.

## kongctl metadata

In the input configuration, you can provide some kongctl-specific metadata values that affect the behavior of the
declarative system. You can provide this `kongctl` section on individual resources or at the configuration file level. 

These values are stored on resources via the {{site.konnect_short_name}} [resource labels](/konnect-platform/konnect-labels/),
so only resources that support labels are supported. In general, only parent resources support labels and child 
resources inherit the values from their parents.

### Namespace 

The `namespace` field allows you to define ownership and isolation of resources. You can use any namespace value, but common patterns are teams (finance, engineering) or environments (prod, dev).

**Child resources** automatically inherit the namespace from their parent.

```yaml
apis:
  - ref: billing-api
    name: "Billing API"
    kongctl:
      namespace: finance-team
```

### Protected resources

When a resource is marked `protected: true`, the kongctl declarative planner does not allow planning updates or deletes to those resources. To update or delete these resources, change the resource from `protected: true` to `protected: false`. Once you change this, you can make subsequent changes.

```yaml
portals:
  - ref: production-portal
    name: "Production Portal"
    kongctl:
      protected: true  # Cannot be deleted
```

### File-level defaults

At the file level, you can use `_defaults` to set default metadata for all resources in a file:

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
  - file_default: Not set
    resource_value: '`""` (empty)'
    result: ERROR
    notes: Empty namespace not allowed
  - file_default: team-b
    resource_value: '`""` (empty)'
    result: ERROR
    notes: Empty namespace not allowed
  - file_default: '`""` (empty)'
    resource_value: Any value
    result: ERROR
    notes: Empty default not allowed
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
  - file_default: Not set
    resource_value: false
    result: "`false`"
    notes: Explicit false
  - file_default: false
    resource_value: true
    result: "`true`"
    notes: Resource overrides
{% endtable %}
<!--vale on-->

### Namespace enforcement flags

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

Unlike other declarative solutions, kongctl doesn't maintain any local state storage to complete its planning and execution. Instead, it does the following:

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

### Loading values from environment variables

Use `!env` to load a value from an environment variable:

```yaml
portals:
  - ref: env-portal
    name: env-portal
    description: !env PORTAL_DESCRIPTION
```

You can extract a field from a YAML or JSON value stored in the variable using `#` notation:

```yaml
api_documents:
  - ref: env-doc
    api_id: petstore-api
    title: !env DOC_METADATA#title
    content: !env DOC_METADATA#content
    slug: getting-started
```

Map syntax is also supported:

```yaml
api_documents:
  - ref: env-doc
    api_id: petstore-api
    title: !env
      var: DOC_METADATA
      extract: title
    content: !env
      var: DOC_METADATA
      extract: content
    slug: getting-started
```

`!env` extraction parses the environment variable as YAML or JSON before reading the requested field path.

#### `!env` behavior

* `!env` is supported on string-typed fields.
* Unset environment variables are treated as errors.
* Empty-but-set environment variables are allowed.
* During planning, kongctl resolves the current environment value to calculate changes.
* Saved plan files preserve the deferred `!env` reference rather than the resolved plaintext value.
* During execution, kongctl performs a fresh environment lookup for each deferred `!env` value.
* In direct `apply`, `sync`, and `delete` runs, both lookups happen in the same process invocation and will usually observe the same value.
* When execution uses a saved plan with `--plan`, planning and execution happen in separate invocations, so environment values may differ.
* Human-readable plan and diff output redact `!env` values.

### Write-only secret fields

Some {{site.konnect_short_name}} APIs accept secret values on create or update but do not return them in `get` or `list` responses. Common examples include:

* Portal identity provider `config.client_secret`
* DCR provider secrets such as `dcr_token`, `api_key`, and `initial_client_secret`
* Event gateway schema registry authentication `password`

For these fields, kongctl skips the field during diff calculation rather than assuming drift on every run. This means:

* The initial create or update still sends the configured secret value.
* Re-applying the same configuration is a no-op rather than planning a perpetual update.
* Changing only a write-only secret may not be detectable from live state, so `plan` may show no changes even if the configured value differs from what is stored in {{site.konnect_short_name}}.

To rotate a write-only secret declaratively, change it alongside another observable field, or recreate the resource if the API does not provide a safe observable signal for that update.

### Path resolution and security

All file paths are resolved relative to the directory containing the configuration file. Path resolution has the following security features:
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

### External resources and namespaces

External resources have the following behavior with respect to namespaces and sync planning:

* **Cannot declare `kongctl` metadata**: Supplying `kongctl.namespace` or `kongctl.protected` on an external resource results in a parsing error. File-level `_defaults` are ignored for external resources.
* **Not included in sync planning**: External resources do not add their namespaces to sync deletion calculations. Only managed parent resources are considered when sync calculates deletes.
* **Child resources are still planned**: Child resources nested under an external parent are planned by resolving the external parent's {{site.konnect_short_name}} ID. Ensure the owning team labels the parent (for example via `kongctl adopt`) so the ID can be resolved.

### Portal audit log webhooks

Portal audit log webhooks can reference organization audit log destinations managed outside kongctl. Declare those destinations as external resources under `audit-logs.destinations`, then reference them from a portal webhook with `!ref`:

```yaml
portals:
  - ref: docs-portal
    name: Docs Portal
    audit_log_webhook:
      ref: docs-portal-audit-log-webhook
      enabled: true
      audit_log_destination_id: !ref foo

audit-logs:
  destinations:
    - ref: foo
      _external:
        selector:
          matchFields:
            name: foo
```

`audit-logs.destinations` supports `_external.id` and `_external.selector.matchFields.name`. Destination resources cannot declare `kongctl` metadata and are not created, updated, or deleted by declarative apply. In sync mode, omitted portal webhook configuration is ignored unless an `audit_log_webhook` block is explicitly present for that portal. To remove an existing webhook while retaining the portal, declare `audit_log_webhook: {}`.

## Best practices

### Multi-team setup

Each team manages their own namespace using file-level defaults:

```yaml
# team-alpha/config.yaml
_defaults:
  kongctl:
    namespace: team-alpha

apis:
  - ref: frontend-api
    name: "Frontend API"
    # Automatically in team-alpha namespace
```

### Environment management

Use configuration profiles for different environments:

```bash
# Development environment
kongctl apply -f config.yaml --profile dev

# Production environment
kongctl apply -f config.yaml --profile prod
```

### Protect critical resources

Mark production resources as protected to prevent accidental deletion:

```yaml
apis:
  - ref: production-api
    name: "Production API"
    kongctl:
      namespace: production
      protected: true
```

### Plan artifact workflow

Use the two-phase workflow for production changes:

```bash
# Generate plan
kongctl plan -f config.yaml --output-file plan.json

# Review in pull request or approval process
kongctl diff --plan plan.json

# Apply after approval
kongctl apply --plan plan.json
```

For CI/CD pipelines, generate and store plans as build artifacts, then apply them after approval:

```bash
# CI: generate plan and store as artifact
kongctl plan -f production-config.yaml \
  --output-file plan-$(date +%Y%m%d-%H%M%S).json

# After approval: apply the plan
kongctl apply --plan plan-20240115-142530.json --auto-approve
```

### Common mistakes to avoid

**Setting `kongctl` metadata on child resources**:

```yaml
# Wrong
apis:
  - ref: my-api
    kongctl:
      namespace: team-a
    versions:
      - ref: v1
        kongctl:        # Error: not supported on child resources
          protected: true

# Correct
apis:
  - ref: my-api
    kongctl:
      namespace: team-a
      protected: true
    versions:
      - ref: v1
```

**Using `name` instead of `ref` for resource references**:

```yaml
# Wrong
api_publications:
  - ref: pub1
    api: "Users API"  # Error: must use ref, not name

# Correct
api_publications:
  - ref: pub1
    api: users-api  # Use the ref value
```

### Field validation

kongctl uses strict YAML validation. Unknown fields are rejected with a suggestion:

```yaml
portals:
  - ref: my-portal
    name: "My Portal"
    lables:  # Error: unknown field 'lables'. Did you mean 'labels'?
      team: platform
```

Common field name mistakes:
* `lables` should be `labels`
* `descriptin` should be `description`
* `displayname` should be `display_name`

## Examples

For complete working examples, see the [kongctl examples directory](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative).

## Troubleshooting

### Authentication failures

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

Enable trace logging for HTTP requests:

```bash
kongctl apply -f config.yaml --log-level trace
```

## Resource notes

### Portal custom domains

* `kongctl plan` and `apply` diff the live {{site.konnect_short_name}} state before deciding what action to schedule. The portal custom domain API only returns a subset of fields (`hostname`, `enabled`, verification method, CNAME status, `skip_ca_check`, timestamps). The raw certificate and private key are never returned.
* Because the `UpdatePortalCustomDomain` endpoint only patches the `enabled` flag, the planner emits an `UPDATE` change when the desired `enabled` value differs. Every other drift (hostname, verification method, `skip_ca_check`) is treated as an in-place replace: `DELETE` followed by `CREATE`.
* Pure certificate rotations that keep the same verification method and `skip_ca_check` setting are invisible to the diff because {{site.konnect_short_name}} does not echo those values. To force a replacement, temporarily change a detectable field (for example, toggle `skip_ca_check` or switch verification method), or remove the domain from configuration, apply, and then reintroduce it with the new certificate material.
