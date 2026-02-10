---
title: kongctl and decK
description: Learn how to use kongctl and decK together for declarative management of the entire API platform

beta: true

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

tags:
  - cli

breadcrumbs:
  - /kongctl/

related_resources:
  - text: kongctl declarative configuration reference
    url: /kongctl/declarative/
next_steps:
  - text: Guide for managing {{site.konnect_short_name}} resources declaratively
    url: /kongctl/declarative/
  - text: Learn kongctl authorization options
    url: /kongctl/authentication/
  - text: kongctl configuration reference guide
    url: /kongctl/config/
  - text: kongctl troubleshooting guide
    url: /kongctl/troubleshooting/
  - text: decK documentation
    url: /deck/
---

kongctl integrates with [decK](/deck/) to provide comprehensive declarative management of your entire {{site.konnect_short_name}} API platform. While kongctl manages {{site.konnect_short_name}} platform resources like control planes, Dev Portals, and APIs, decK manages Gateway configuration resources such as Services, Routes, and plugins. By combining both tools in a single declarative workflow, you can manage your complete infrastructure as code.

The integration allows kongctl to orchestrate decK operations as part of its plan-based workflow. When you declare Gateway configuration managed by decK in your kongctl configuration files, kongctl automatically invokes decK at the appropriate time during plan generation and execution.

Key benefits:

* **Unified workflow**: Manage platform and Gateway resources together in a single plan.
* **Consistent interface**: Use familiar kongctl commands (`plan`, `diff`, `apply`, `sync`).
* **Dependency resolution**: kongctl resolves control plane identifiers and Gateway entity references before invoking decK.
* **Audit trail**: decK operations are included in kongctl plan artifacts.

## Configuration

decK integration is configured on control planes using the `_deck` pseudo-resource. kongctl runs decK once per control plane that declares `_deck`, then resolves external Gateway entities by selector name.

Basic example:

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

In this example:
* The `prod-cp` control plane has decK configuration defined.
* decK will apply the `kong.yaml` state file with the `--select-tag=kongctl` flag.
* The `billing-gw` Gateway Service is resolved externally by finding a Service with `name: "billing-service"`.

### Configuration fields

#### `_deck`

The `_deck` field configures the decK integration for a control plane:

* **Placement**: Only allowed on control planes
* **Cardinality**: Only one `_deck` configuration per control plane
* **Required child values**:
  * `files`: List of decK state file paths (at least one required)
  * `flags`: Optional list of additional decK CLI flags

#### `_deck.files`

Specifies the decK state files to apply:

```yaml
_deck:
  files:
    - "kong.yaml"
    - "plugins.yaml"
```

* Must include at least one state file
* Paths are relative to the declarative config file
* Must remain within the `--base-dir` boundary (default: config file directory)

#### `_deck.flags`

Additional decK command-line flags to pass:

```yaml
_deck:
  flags:
    - "--select-tag=kongctl"
    - "--parallelism=10"
```

{:.warning}
> **Important**: Do not include {{site.konnect_short_name}} authentication flags (`--konnect-token`, `--konnect-control-plane-name`, `--konnect-addr`) or output flags (`--json-output`, `--no-color`). kongctl injects these automatically.

### External Gateway Service resolution
	
When Gateway Services are managed by decK, reference them as external resources in your kongctl configuration:

```yaml
gateway_services:
  - ref: billing-gw
    _external:
      selector:
        matchFields:
          name: "billing-service"
```

Keep the following in mind:
* `_external.selector.matchFields.name` is required for external Gateway services.
* The `name` field must be the only selector field.
* kongctl resolves the Gateway Service after decK applies the configuration.
* External Gateway Services can't use `_external.requires.deck`, resolution happens automatically

## Behavior and workflow

The following sections describe how decK and kongctl behave when used together.

### Command behavior

kongctl integrates decK differently depending on the command:

<!--vale off-->
{% table %}
columns:
  - title: Command
    key: command
  - title: decK Operation
    key: deck
  - title: Behavior
    key: behavior
rows:
  - command: "`kongctl plan`"
    deck: "`deck gateway diff`"
    behavior: "Determines if changes are needed"
  - command: "`kongctl diff`"
    deck: "`deck gateway diff`"
    behavior: "Shows proposed Gateway configuration changes"
  - command: "`kongctl apply`"
    deck: "`deck gateway apply`"
    behavior: "Creates/updates Gateway configuration (no deletions)"
  - command: "`kongctl sync`"
    deck: "`deck gateway sync`"
    behavior: "Creates/updates/deletes Gateway configuration"
{% endtable %}
<!--vale on-->


{:.info}
> **Note**: For `apply` mode, deletions reported by `deck diff` are ignored. Only `sync` mode performs deletions.

### Execution order

During plan execution, kongctl orchestrates operations in this order:

1. Creates or updates the control plane (if needed)
2. Runs `deck gateway apply` or `deck gateway sync` on the control plane
3. Resolves external Gateway Services by selector
4. Continues with dependent resources

### Plan artifacts and portability

kongctl plans store decK configuration and base directories for later execution:

* **Base directory storage**: Relative to plan file location
* **stdout plans**: Base directory is relative to current working directory
* **Portable plans**: Use `--output-file` to create portable plan files
* **Plan application**: Resolves paths from plan file directory (or current directory with `--plan -`)
* **Resolution targets**: Plans include `post_resolution_targets` on `_deck` change entries with control plane IDs and Gateway Service selectors

### Control plane creation

If a control plane created in the same plan:

* kongctl can't run `deck gateway diff` (because the control plane ID isn't available yet)
* kongctl automatically includes the external tool step in the plan
* decK runs after the control plane is created during `apply`

### Authentication and output

kongctl automatically injects required flags when invoking decK.

**Authentication flags**:
* `--konnect-token`: Current kongctl session token
* `--konnect-control-plane-name`: Target control plane name or ID
* `--konnect-addr`: {{site.konnect_short_name}} API endpoint

**Output flags**:
* `--json-output`: Structured output for parsing
* `--no-color`: Removes ANSI color codes

{:.warning}
> **Do not specify these flags yourself**. kongctl will add them automatically and duplicate flags may cause errors.

## Select tags and resource ownership

When using `deck gateway sync`, it's critical to use select tags to prevent decK from deleting resources owned by other configurations:

```yaml
# In your kong.yaml decK state file
_info:
  select_tags:
    - kongctl

services:
  - name: billing-service
    url: https://billing.internal
    tags:
      - kongctl
    routes:
      - name: billing-route
        paths:
          - /billing
        tags:
          - kongctl
```

{:.warning}
> **Important**: kongctl does not inject select tags automatically. You must:
> 1. Define `_info.select_tags` in your decK state files
> 2. Add matching `tags` to all entities
> 3. Pass the corresponding `--select-tag` flag via `_deck.flags`

Without proper tagging, `deck gateway sync` may delete resources managed by other teams or tools.

## Path resolution and security

All decK file paths follow kongctl's path resolution rules:

* **Relative resolution**: Paths are relative to the config file directory
* **Base directory**: Defaults to config file directory, override with `--base-dir`
* **Security boundaries**: Relative paths with `..` must stay within base directory
* **Absolute paths**: Blocked for security

```yaml
# Allowed (within base directory)
_deck:
  files:
    - "gateway/kong.yaml"
    - "../shared/common.yaml"  # If within base directory

# Blocked (absolute path)
_deck:
  files:
    - "/etc/kong/config.yaml"
```

## Complete example

Here's a complete example managing a control plane with Gateway configuration:

```yaml
_defaults:
  kongctl:
    namespace: platform-team

control_planes:
  - ref: production-cp
    name: "production"
    cluster_type: "CLUSTER_TYPE_K8S_INGRESS_CONTROLLER"
    _deck:
      files:
        - "gateway/production.yaml"
      flags:
        - "--select-tag=platform-team"
        - "--parallelism=5"

    gateway_services:
      # External service managed by decK
      - ref: api-gateway-svc
        _external:
          selector:
            matchFields:
              name: "api-gateway"

# API product version associated with the Gateway Service
api_product_versions:
  - ref: users-api-v1-prod
    api_product: users-api
    version: v1
    gateway_service: !ref api-gateway-svc#id
```

Corresponding `gateway/production.yaml` decK file:

```yaml
_format_version: "3.0"
_info:
  select_tags:
    - platform-team

services:
  - name: api-gateway
    url: https://backend.internal
    tags:
      - platform-team
    routes:
      - name: users-route
        paths:
          - /users
        tags:
          - platform-team
    plugins:
      - name: rate-limiting
        config:
          minute: 100
        tags:
          - platform-team
```

## Limitations

Keep the following limitations in mind:
* `_external.requires.deck` is not supported for Gateway service resolution
* decK configuration is only allowed on control planes, not on other resource types
* Only one `_deck` configuration per control plane
* Control plane must exist (or be created in same plan) before decK can run

## Troubleshooting

### decK command not found

If you get the `Error: deck command not found` message, ensure decK is installed and available in your PATH.
	
1. Verify decK installation:
   ```sh
   deck version
   ```
1. [Install decK](/deck/#install-deck) if needed.

### Authentication errors from decK

If you get the `Error: failed to authenticate with Konnect` error message, do the following:

* Verify kongctl authentication: `kongctl get me`
* Re-authenticate if needed: `kongctl login`
* kongctl passes its token to decK automatically

### Unexpected deletions during sync

If you get the `deleting service api-gateway (created by another team)` message while syncing, do the following:

* Ensure `_info.select_tags` is defined in decK state files
* Add matching `tags` to all entities
* Include the corresponding `--select-tag` flag in `_deck.flags`

### File path errors

If you get the `Error: failed to load deck file: file not found` message, do the following:

* Verify that the file path is correct and relative to the config file.
* Check that the file exists in base directory boundary.
* Use the `--base-dir` flag if needed.

### Control plane ID not available

This is expected when creating a new control plane in the same plan. kongctl automatically includes the decK step and runs it after control plane creation.

