---
title: Declarative configuration with kongctl

description: Learn how to manage {{site.konnect_product_name}} infrastructure as code using declarative YAML configuration.

content_type: reference
layout: reference

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

This page covers what you need to know for managing {{site.konnect_short_name}}
resources using the `kongctl` declarative configuration approach.
For supported resource types and field-level resource definitions see the [kongctl declarative resource reference](/kongctl/supported-resources/).

## Overview

`kongctl`'s declarative management feature enables you to
manage your [{{site.konnect_short_name}}](/konnect/) resources with
simple YAML declaration files and a simple state-free CLI tool.

### Key Principles

1. **Configuration manifests**: Configuration is expressed as simple YAML files that describe the desired state of your {{site.konnect_short_name}} resources.
   Configuration files can be split into multiple files and directories for modularity and reuse.
1. **Plan-Based**: Plans are objects that represent required changes to move a set of resources from one state to another, desired, state.
   In `kongctl`, plan artifacts are first-class concepts that can be created, stored, reviewed, and applied. Plans are represented as JSON objects
   and can be generated and stored as files for later application. When running declarative commands, if plans are not provided
   they are generated implicitly and executed immediately.
1. **State-Free**: `kongctl` does not use a state file or database to store the current state. The system relies on querying of the
   online {{site.konnect_short_name}} state in order to calculate plans and apply changes.
1. **Namespace Resource Isolation**: Namespaces provide a way to isolate resources however the user desires (teams, environments, etc...).
   Each resource under management is assigned to one namespace, and resources in other namespaces are *not considered* when calculating plans or
   applying changes. A `default` namespace is used if none is specified in input configurations.

## Quick Start

### Prerequisites

1. **{{site.konnect_short_name}} Account**: [Sign up for free](https://konghq.com/products/kong-konnect/register)
2. **`kongctl` installed**: See [installation instructions](/kongctl/#installation)
3. **Authenticated with {{site.konnect_short_name}}**: Run `kongctl login`

### Create Your First Configuration

Create a working directory:

```shell
mkdir kong-portal && cd kong-portal
```

Create a file named `portal.yaml`:

```yaml
portals:
  - ref: my-portal
    name: "my-developer-portal"
    display_name: "My Developer Portal"
    description: "API documentation for developers"
    authentication_enabled: false
    default_api_visibility: "public"
    default_page_visibility: "public"

apis:
  - ref: users-api
    name: "Users API"
    description: "API for user management"

    publications:
      - ref: users-api-publication
        portal_id: my-portal
```

Preview changes:

```shell
kongctl diff --mode apply -f portal.yaml
```

Apply configuration:

```shell
kongctl apply -f portal.yaml
```

Verify resources with `kongctl get` commands:

```shell
kongctl get portals
```

```shell
kongctl get apis
```

Your developer portal and API are now live! Visit the [{{site.konnect_short_name}} Console](https://cloud.konghq.com/us/portals/)
to see your developer portal with the published API.

## Core Concepts

### Resource Identity

Resources can have multiple identifiers:

- **ref**: `kongctl` declarative engine identifier. `ref` is used to identify the resource uniquely within a
    given set of declarative configurations. `ref` is not written to the remote {{site.konnect_short_name}} system and
    must be unique across all resources in a given set of input configuration files. This value is used to
    create inter-configuration references between resources.
- **id**: *Most* {{site.konnect_short_name}} resources have an `id` field which is a {{site.konnect_short_name}}
    assigned UUID. This field is not stored in declarative configuration files but will be used internally
    by the declarative engine.
- **name**: *Many* {{site.konnect_short_name}} resources have a `name` field which *may or may not* be
    subject to a unique constraint within an organization for that resource type.

Top-level resource keys and field names in declarative YAML are stable
configuration contract names. Use the names documented in the
[kongctl declarative resource reference](/kongctl/supported-resources/), and use
`ref` values when one resource needs to refer to another.

```yaml
application_auth_strategies:
  - ref: oauth-strategy              # ref identifies a resource within a configuration
    name: "OAuth 2.0 Strategy"       # Identifies an auth strategy within {{site.konnect_short_name}}

portals:
  - ref: developer-portal
    name: "Developer Portal"
    default_application_auth_strategy: oauth-strategy  # References the auth strategy by its ref value
```

### Plan Artifacts

Plans are central to how `kongctl` manages resource state. Plans are objects which
define the required steps to move a set of resources from their current state to a
desired state. Plans can be created, stored, reviewed, and applied at a later time
and are stored as JSON files. Plans are not required to be used,
but can enable advanced workflows.

#### How Planning Works

The declarative configuration commands
(`apply`, `sync`, `delete`, `diff`) commands use the planning engine internally:

**Implicit Planning** (direct execution):

```shell
# Internally generates plan and executes it
kongctl apply -f config.yaml
```

**Explicit Planning** (two-phase execution):

```shell
# Phase 1: Generate plan artifact
kongctl plan --mode apply -f config.yaml --output-file plan.json
```

```shell
# Phase 2: Execute plan artifact (can be done later)
kongctl apply --plan plan.json
```

#### Why Use Plan Artifacts?

Plan artifacts enable more advanced workflows:

- **Audit Trail**: Store plans in version control alongside configurations
- **Review Process**: Share plans and review with team members before execution
- **Deferred Execution**: Generate plans in CI, apply them after approval
- **Rollback Safety**: Keep previously applied plans for rollback analysis
- **Compliance**: Document exactly what changes were planned

## Configuration Structure

### Basic Structure

```yaml
# Optional defaults section
_defaults:
  kongctl: # kongctl metadata defaults
    namespace: production
    protected: false

portals: # List of Parent portal resources
  - ref: developer-portal # ref is required on all resources
    name: "developer-portal"
    display_name: "Developer Portal"
    description: "API documentation hub"
    kongctl: # kongctl metadata defined explicitly on resource, overrides _defaults
      namespace: platform-team
      protected: true
```

### Parent vs Child Resources

Generally the main concepts in the {{site.konnect_short_name}} system are collections and many
of them support child resources underneath them.

**Parent Resource Examples**:

- `apis`
- `portals`
- `application_auth_strategies`
- `control_planes`
- `analytics.dashboards`
- `organization.teams`
- `event_gateways`

**Child Resource Examples**:

- `api.versions`
- `api.publications`
- `api.implementations`
- `api.documents`
- `portal.pages`
- `portal.snippets`
- `portal.customization`
- `portal.custom_domain`
- `portal.email_config`
- `portal.email_templates`

See the [kongctl declarative resource reference](/kongctl/supported-resources/) for more details on supported resources.

### Hierarchical vs Flattened configuration

Parents are defined at the root of a configuration while
children can be expressed both nested under their parent
and at the root with a parent reference field.

**Hierarchical Configuration**:

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
        portal_id: !ref main-portal
        visibility: public
```

**Flattened Configuration**:

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
    portal_id: !ref main-portal
```

## kongctl metadata

The `kongctl` section provides metadata for resource management.
This metadata is stored in {{site.konnect_short_name}} labels and labels are only
provided on parent resources. Thus, `kongctl` metadata is
**only supported on parent resources**.

### Protected Resources

The `protected` field prevents accidental deletion of critical resources:

```yaml
portals:
  - ref: production-portal
    name: "Production Portal"
    kongctl:
      protected: true  # Cannot be deleted until protection is removed
```

### Namespace Management

The `namespace` field enables resource isolation:

```yaml
apis:
  - ref: billing-api
    name: "Billing API"
    kongctl:
      namespace: finance-team  # Owned by finance team
      protected: false
```

### File-Level Defaults

Use `_defaults` to set default values for all resources in a file:

```yaml
_defaults:
  kongctl:
    namespace: platform-team
    protected: true

portals:
  - ref: api-portal
    name: "API Portal"
    # Inherits namespace: platform-team and protected: true

  - ref: test-portal
    name: "Test Portal"
    kongctl:
      namespace: qa-team
      protected: false
    # Overrides both defaults
```

### Namespace and Protected Field Behavior

`kongctl` provides some default behavior depending on how metadata fields
are specified or omitted. The following tables summarize the behavior.

#### `namespace` Field Behavior

| File Default | Resource Value | Final Result | Notes                        |
|--------------|----------------|--------------|------------------------------|
| Not set      | Not set        | "default"    | System default               |
| Not set      | "team-a"       | "team-a"     | Resource explicit            |
| Not set      | "" (empty)     | ERROR        | Empty namespace not allowed  |
| "team-b"     | Not set        | "team-b"     | Inherits default             |
| "team-b"     | "team-a"       | "team-a"     | Resource overrides           |
| "team-b"     | "" (empty)     | ERROR        | Empty namespace not allowed  |
| "" (empty)   | Any value      | ERROR        | Empty default not allowed    |

#### `protected` Field Behavior

| File Default | Resource Value | Final Result | Notes              |
|--------------|----------------|--------------|-------------------|
| Not set      | Not set        | false        | System default     |
| Not set      | true           | true         | Resource explicit  |
| Not set      | false          | false        | Explicit false     |
| true         | Not set        | true         | Inherits default   |
| true         | false          | false        | Resource overrides |
| false        | true           | true         | Resource overrides |

Child resources automatically inherit the metadata of their parent resource:

### Namespace Enforcement Flags

The `kongctl plan` command provides built-in namespace guardrails:

- `--require-any-namespace` forces every managed resource to declare a namespace via `kongctl.namespace`
  or `_defaults.kongctl.namespace`.
- `--require-namespace=<ns>` restricts planning to the provided namespaces (repeat or comma-separate the flag
  to allow multiple values).

These flags help prevent accidentally operating on unexpected namespaces, especially when running in sync mode.

## External Resources and Namespaces

External resources (`_external` pseudo-resource) are references to {{site.konnect_short_name}} objects that are managed elsewhere
but are "selected" by the `kongctl` declarative engine so they can be referenced by other resources under management.

```yaml
# External portal definition - this tells kongctl that this portal
# is managed externally (by the platform team) but we need to reference it
portals:
  - ref: shared-developer-portal
    _external:
      selector:
        matchFields:
          name: "Shared Developer Portal"
```

Because kongctl does not own those resources:
- External resources **cannot** declare `kongctl` metadata. Supplying `kongctl.namespace` or `kongctl.protected`
  on an external resource results in a parsing error. File-level defaults are ignored for externals.
- External references do **not** add their namespaces to sync planning. Only namespaces from managed parent
  resources are considered when sync mode calculates deletes.
- Child resources (portal pages, customizations, etc.) are still planned by resolving the external parent's {{site.konnect_short_name}} ID.
  Ensure the owning team labels the parent (for example via `kongctl adopt`) so the ID can be resolved, but you do not
  need to (and cannot) assign a namespace to the external definition itself.

## Resources managed by decK

[decK](/deck/) integration is configured on control planes via the `_deck` pseudo-resource. kongctl runs decK once per
control plane that declares `_deck`, then resolves external gateway services by selector name. `_external.requires.deck`
is not supported.

```yaml
control_planes:
  - ref: prod-cp
    name: "prod-cp"
    _deck:
      files:
        - "kong.yaml"
      flags:
        - "--select-tag=kongctl"

    gateway_services:
      - ref: billing-gw
        _external:
          selector:
            matchFields:
              name: "billing-service"
```

Important notes for decK integration:
- `_deck` is allowed only on control planes and only one `_deck` config is allowed per control plane.
- `_deck.files` must include at least one state file.
- `_deck.flags` can include additional decK flags (but not {{site.konnect_short_name}} auth or output flags).
- `_external.selector.matchFields.name` is required for external gateway services and must be the only selector field.
- kongctl runs exactly one `deck gateway apply` or `deck gateway sync` per control plane that declares `_deck`.
- decK state files should include `_info.select_tags` and matching `tags` on entities so `sync` does not delete
  resources owned by other decK files. kongctl does not inject select tags for you.
- Relative decK file paths are resolved relative to the declarative config file and must remain within the
  `--base-dir` boundary (default: the config file directory).
- Plan files store decK base directories relative to the plan file location. When emitting a plan to stdout,
  the base directory is made relative to the current working directory (use `--output-file` for portable plans).
  Applying a plan resolves them from the plan file directory (or the current working directory when using `--plan -`).
- `kongctl plan`/`diff` runs `deck gateway diff` to decide whether an external tool change is needed.
  `kongctl apply` runs `deck gateway apply` and `kongctl sync` runs `deck gateway sync`.
  For apply mode, deletes reported by decK diff are ignored.
- If the control plane is being created in the same plan (or the ID is not available), kongctl skips decK diff and
  includes the external tool step.
- For gateway steps, kongctl injects {{site.konnect_short_name}} auth flags and output flags (`--json-output --no-color`);
  do not supply `--konnect-token`, `--konnect-control-plane-name`, `--konnect-addr`, or output flags yourself.
- Plans represent decK resolution targets explicitly via `post_resolution_targets` on the `_deck` change entry,
  including control plane identifiers and the gateway service selector.

## YAML Tags

YAML tags are like preprocessors for YAML file data. They allow you to
load content from external files, reference across resources, load values
from environment variables, and extract specific values from structured
data. Over time more tags may be added to support various functions and
use cases.

### Loading File Content to YAML Fields

Load the entire content of a file as a string:

```yaml
apis:
  - ref: users-api
    name: "Users API"
    description: !file ./docs/api-description.md
```
All file paths are resolved relative to the directory containing the
configuration file:

```
project/
├── config.yaml          # Main config file
├── specs/
│   ├── users-api.yaml
│   └── products-api.yaml
└── docs/
    └── descriptions.txt
```

In `config.yaml`:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/users-api.yaml#info.title
    description: !file ./docs/descriptions.txt
```

Supported file types: Any text file (`.txt`, `.md`, `.yaml`, `.json`, etc.)

#### Security Features

**Path Traversal Prevention**: Absolute paths are blocked. Relative paths may include
`..`, but the resolved path must stay within the base directory boundary. By default,
the boundary is the root of each `-f` source (file: its parent dir, dir: the directory itself).
For stdin, the boundary defaults to the current working directory. Set the base directory with
`--base-dir` or `konnect.declarative.base-dir` (`KONGCTL_<PROFILE>_KONNECT_DECLARATIVE_BASE_DIR`,
for example `KONGCTL_DEFAULT_KONNECT_DECLARATIVE_BASE_DIR`).

```yaml
# These will fail with security errors
description: !file /etc/passwd

# This will fail if it resolves outside the base directory
config: !file ../../../sensitive/file.yaml

# These are allowed (if they stay within the base directory)
description: !file ../docs/description.txt
config: !file ./config/settings.yaml
```

**File Size Limits**: Files are limited to 10MB.

#### Performance Features

**File Caching**: Files are cached during a single execution to improve
performance:

```yaml
apis:
  - ref: api-1
    name: !file ./common.yaml#api.name        # File loaded and cached
    description: !file ./common.yaml#api.desc # Uses cached version
  - ref: api-2
    team: !file ./common.yaml#team.name       # Uses cached version
```

#### Value Extraction

You can extract specific values from structured data loaded from the `file` tag
with this hash (`#`) notation:

```yaml
apis:
  - ref: users-api
    name: !file ./specs/openapi.yaml#info.title # loads info.title field from the openapi.yaml file
    description: !file ./specs/openapi.yaml#info.description
    version: !file ./specs/openapi.yaml#info.version

    versions:
      - ref: v1
        spec: !file ./specs/openapi.yaml
```

Alternatively values can be extracted using this map format:

```yaml
apis:
  - ref: products-api
    name: !file
      path: ./specs/products.yaml
      extract: info.title
    labels:
      contact: !file
        path: ./specs/products.yaml
        extract: info.contact.email
```

### Loading Values From Environment Variables

Use `!env` to load a value from an environment variable into a string
field:

```yaml
portals:
  - ref: env-portal
    name: env-portal
    description: !env PORTAL_DESCRIPTION
```

Scalar syntax supports extraction with `#`:

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

`!env` extraction parses the environment variable as YAML or JSON before
reading the requested field path.

A runnable example is available in
[docs/examples/declarative/env/](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/env/).

#### !env Behavior

- `!env` is supported on string-typed fields in this release.
- Unset environment variables are treated as errors.
- Empty-but-set environment variables are allowed.
- During planning, `kongctl` resolves the current environment value to
  calculate changes.
- Saved plan files preserve the deferred `!env` reference instead of the
  resolved plaintext value.
- During execution, `kongctl` performs a fresh environment lookup for each
  deferred `!env` value instead of reusing the value observed during
  planning.
- When you run `apply`, `sync`, or `delete` directly from configuration
  files, `kongctl` still plans first and then performs that second lookup
  during execution in the same command invocation.
- In direct `apply`, `sync`, and `delete` runs, both lookups happen within
  the same `kongctl` process, so they will usually observe the same process
  environment.
- When execution uses a saved plan with `--plan`, planning and execution
  happen in separate command invocations, so environment values may differ
  between them and the executed value may differ from what was observed
  while planning.
- Human-readable plan and diff output redact `!env` values.

## Write-only Secret Fields

Some {{site.konnect_short_name}} APIs accept secret values on create or update but do not return
them from `get` or `list` responses. Common examples include:

- Portal identity provider `config.client_secret`
- DCR provider secrets such as `dcr_token`, `api_key`, and
  `initial_client_secret`
- Event Gateway schema registry authentication `password`

For these fields, `kongctl` prefers idempotent planning over perpetual
updates. When the API does not expose the current value, the planner skips
that field during diff calculation instead of assuming drift on every run.

This means:

- The initial create or update still sends the configured secret value.
- Re-applying the same declarative configuration will usually be a no-op
  instead of planning an update forever.
- Changing only a write-only secret may not be detectable from live state, so
  `plan` may show no changes even though the configured secret value differs
  from what is currently stored in {{site.konnect_short_name}}.

When you need to rotate a write-only secret declaratively, make the change
alongside another observable field, or recreate the resource if the API does
not provide a safe observable signal for that update.

## Commands Reference

The following are high level descriptions of commands for declarative
configuration management. See the command usage text for details on
command usage, flags and options.

### plan

Create a plan - a JSON file containing the set of planned changes to a set of resources.
Plans are generated with either `--mode apply` or `--mode sync`. Apply mode
creates and updates configured resources only. Sync mode also deletes managed
resources, but only for resource collections that are explicitly present in the
input configuration.

Generate an apply plan and output to STDOUT:

```shell
kongctl plan -f config.yaml --mode apply
```

Generate a sync plan and output to STDOUT:

```shell
kongctl plan -f config.yaml --mode sync
```

### apply

Applying a configuration will create or update resources to match the desired state
and will **not delete** resources. Because `apply` does not delete resources, it can
be used for incremental application of resource configurations. For example, you could
apply a `portal` in one command and then later apply `apis` in a separate command.

Apply directly from config:

```shell
kongctl apply -f config.yaml
```

Apply from saved plan:

```shell
kongctl apply --plan plan.json
```

Preview changes without applying:

```shell
kongctl apply -f config.yaml --dry-run
```

### sync

`sync` applies a set of configurations including deleting managed resources that
are missing from explicitly scoped collections.

Sync scope is based on YAML key presence:

- Omitted resource collections are ignored.
- Explicit empty root lists mean the desired count is zero. For example,
  `apis: []` deletes managed APIs in the selected namespace.
- Parent and child collections are scoped separately. A portal block without
  `pages` does not delete portal pages. Use `pages: []` under that portal to
  declare that the portal should have no pages.
- Map-shaped child collections use an empty object as the empty collection. For
  example, `email_templates: {}` means the portal should have no customized
  email templates.
- Singleton child sections use the same key-presence rule, but `{}` and `null`
  are intentionally different. Omit a singleton key to ignore that child.
  Provide an object with fields to manage or update it. For optional,
  delete-capable portal singletons such as `custom_domain`, `email_config`, and
  `audit_log_webhook`, an empty object scopes the child with desired count zero:
  `custom_domain: {}` deletes any existing managed custom domain for that
  portal during sync. `null` is rejected because sync does not infer reset or
  delete semantics from null. Update-only singleton sections, such as
  `customization`, cannot be deleted by declaring `{}`.
- Empty child collections must be nested under a parent resource. Root-level
  `api_documents: []` is rejected because it does not identify which API owns
  the desired zero count.

For federated ownership, include the parent resource entry in the team
configuration and scope only the child collection that team owns. When the
parent is managed elsewhere and the resource type supports `_external`, declare
the parent as external and nest the child collection under that parent. This
allows `sync` to plan the child collection without treating the managed parent
collection in the team's namespace as desired state.

```yaml
apis:
  - ref: orders-api
    name: Orders API
    documents: []
```

```yaml
portals:
  - ref: shared-docs-portal
    _external:
      selector:
        matchFields:
          name: "Shared Docs Portal"
    pages: []
```

The external-parent pattern should not be combined with a namespace default
unless the team also intends to scope managed parent resources in that
namespace.

Preview sync changes:

```shell
kongctl sync -f config.yaml --dry-run
```

Sync configuration with a prompt confirmation:

```shell
kongctl sync -f team-config.yaml
```

Skip confirmation prompt (caution!):

```shell
kongctl sync -f config.yaml --auto-approve
```

Sync from a plan artifact:

```shell
kongctl sync --plan plan.json
```

### delete

`delete` plans to delete all resources defined in the input declarative
configuration files from the target {{site.konnect_short_name}} organization.
It is useful for experimentation with a known set of resources or for resetting
a test environment, but it is not a common part of the typical declarative
configuration workflow.

`kongctl delete -f <files>` is equivalent to generating a delete-mode plan for
the input files and executing that plan.

Preview targeted deletions:

```shell
kongctl diff -f config.yaml --mode delete
```

Delete resources declared in a file:

```shell
kongctl delete -f config.yaml
```

{:.warning}
> **Caution**: `delete` plans to delete all resources specified in the input
> configuration. Always verify the changes before approving execution.

### diff

Display preview of changes between current and desired state:

Preview changes in apply mode (CREATE and UPDATE only):

```shell
kongctl diff -f config.yaml --mode apply
```

Preview changes in sync mode (CREATE, UPDATE, and DELETE):

```shell
kongctl diff -f config.yaml --mode sync
```

Preview targeted deletions in delete mode (DELETE only for matching resources):

```shell
kongctl diff -f config.yaml --mode delete
```

Preview changes from a plan artifact:

```shell
kongctl diff --plan plan.json
```

> Note: `--mode` cannot be used with `--plan` because mode is stored in the
> plan artifact metadata.

For `UPDATE` actions, text diff shows only the fields that would be
changed. JSON and YAML outputs expose the same detail in each change's
`changed_fields` object while keeping `fields` as the execution payload.

### adopt

`kongctl` declarative configuration engine will only consider resources that
are part of the list of `kongctl.namespace` values given to it during planning
and execution of changes. There may be cases where you want to bring an
existing {{site.konnect_short_name}} resource into configuration that was created outside of the
configuration management process. The `adopt` command enables you to
add the proper namespace label to an existing {{site.konnect_short_name}} resources without
modifying any other fields. Once you adopt a resource, you need to add the
configuration for it
to your configuration set to ensure it is managed going forward.

Adopt a portal by name:

```shell
kongctl adopt portal my-portal --namespace team-alpha
```

Adopt a control plane by ID:

```shell
kongctl adopt control-plane 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace platform
```

Adopt a custom dashboard by ID:

```shell
kongctl adopt analytics dashboard 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace analytics
```

If the resource already has a `KONGCTL-namespace` label, the command fails
without making changes.

### dump

Export current {{site.konnect_short_name}} resource state to various formats.

```shell
# Export all APIs with their child resources and include debug logging
# to tf-import format
kongctl dump tf-import --resources=api --include-child-resources
```

```shell
# Export all portal and api resources to
# kongctl declarative configuration with format and the team-alpha namespace
kongctl dump declarative --resources=portal,api --default-namespace=team-alpha
```

For custom dashboards created in the {{site.konnect_short_name}} UI, adopt the dashboard first,
then dump it with the same namespace:

```shell
kongctl adopt analytics dashboard 22cd8a0b-72e7-4212-9099-0764f8e9c5ac \
  --namespace analytics
kongctl dump declarative --resources=analytics.dashboards \
  --default-namespace=analytics > dashboards.yaml
kongctl plan -f dashboards.yaml --mode apply
```

## CI/CD Integration

Key principles for CI/CD integration:

1. **Plan on PR**: Generate and review plans in pull requests
2. **Apply on Merge**: Apply reviewed plans when merged to target branch
3. **Environment Separation**: Different configs for dev/staging/prod
4. **Approval Gates**: Require human approval for production

## Best Practices

### Multi-Team Setup

Each team manages their own namespace:

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

### Environment Management

Use configuration profiles for different environments:

```shell
# Development environment
kongctl apply -f config.yaml --profile dev

# Production environment
kongctl apply -f config.yaml --profile prod
```

### Security Best Practices

1. **Protect production resources**:
   ```yaml
   apis:
     - ref: payment-api
       kongctl:
         namespace: production
         protected: true
   ```

2. **Use namespaces for isolation**:
   - One namespace per team
   - Separate namespaces for environments
   - Clear namespace ownership documentation

3. **Version control everything**:
   - Configuration files
   - OpenAPI specifications
   - Documentation

4. **Review plans before applying**:
   - Use `plan` in production
   - Save plans for audit trail
   - Implement approval workflows

### Plan Artifact Workflows

#### Basic Plan Review Workflow

Developer creates plan:

```shell
kongctl plan -f config.yaml --output-file proposed-changes.json
```

Review changes visually:

```shell
kongctl diff --plan proposed-changes.json
```

Share plan for review (commit to git, attach to PR, etc.):

```shell
git add proposed-changes.json
git commit -m "Plan for adding new API endpoints"
```

After approval, apply the plan:

```shell
kongctl apply --plan proposed-changes.json
```

#### Production Deployment with Approval

```shell
# CI/CD Pipeline Stage 1: Plan Generation
kongctl plan -f production-config.yaml \
  --output-file plan-$(date +%Y%m%d-%H%M%S).json

# Stage 2: Manual approval gate
# - Plan artifact is stored as build artifact
# - Team reviews plan details
# - Approval triggers next stage

# Stage 3: Plan Execution
kongctl sync --plan plan-20240115-142530.json --auto-approve
```

#### Emergency Rollback Using Previous Plan

List recent plans (assuming you store them):

```shell
ls -la plans/
```

Review what the previous state included:

```shell
kongctl diff --plan plans/last-known-good.json
```

Revert to previous state:

```shell
kongctl sync --plan plans/last-known-good.json --auto-approve
```

### Common Mistakes to Avoid

**Setting kongctl on child resources**:

```yaml
# WRONG
apis:
  - ref: my-api
    kongctl:
      namespace: team-a
    versions:
      - ref: v1
        kongctl:  # ERROR - not supported on child resources
          protected: true
```

**Correct approach**:

```yaml
# RIGHT
apis:
  - ref: my-api
    kongctl:
      namespace: team-a
      protected: true
    versions:
      - ref: v1
```

**Using name as identifier**:

```yaml
# WRONG - using display name
api_publications:
  - ref: pub1
    api: "Users API"
```

**Use ref for references**:

```yaml
# RIGHT - using ref
api_publications:
  - ref: pub1
    api: users-api
```

### Field Validation

kongctl uses strict YAML validation to catch configuration errors early:

```yaml
# This will cause an error
portals:
  - ref: my-portal
    name: "My Portal"
    lables:  # ERROR: Unknown field 'lables'. Did you mean 'labels'?
      team: platform
```

Common field name errors:

- `lables` → `labels`
- `descriptin` → `description`
- `displayname` → `display_name`
- `strategytype` → `strategy_type`

## Troubleshooting

### Common Issues

**Authentication Failures**:

- Verify PAT is not expired
- Check authentication: `kongctl get me`
- Ensure proper credential storage

**Plan Generation Failures**:

- Validate YAML syntax
- Check file paths are correct
- Verify network connectivity

**Apply Failures**:

- Review plan for conflicts
- Check for protected resources
- Verify dependencies exist

**File Loading Errors**:

```
Error: failed to process file tag: file not found: ./specs/missing.yaml
```

- Verify the file path is correct
- Check that the file exists
- Ensure proper relative path from config file location

### Debugging

Enable verbose logging:

```bash
kongctl apply -f config.yaml --log-level debug
```

Enable trace logging for HTTP requests:

```bash
kongctl apply -f config.yaml --log-level trace
```

For more troubleshooting help, see the [Troubleshooting guide](/kongctl/troubleshooting/).

## Examples

Browse the [examples directory](https://github.com/Kong/kongctl/tree/main/docs/examples/declarative/)

## Related Documentation

- [Troubleshooting guide](/kongctl/troubleshooting/) - Common issues and solutions
