---
title: "Configuration files and resource identity with kongctl"
description: "Choose identifiers, organize nested or root declarations, and load local or remote files."
content_type: reference
layout: reference
works_on:
  - konnect
tools:
  - kongctl
breadcrumbs:
  - /kongctl/
  - /kongctl/declarative/
related_resources:
  - text: Declarative configuration overview
    url: /kongctl/declarative/
  - text: Supported resources
    url: /kongctl/supported-resources/
---

Read this page when organizing manifests, choosing resource identifiers, or
loading local and remote sources.

## Resource identity

Resources can have multiple identifiers:

- **ref**: `kongctl` declarative engine identifier. It must be unique across
  all resources in a given set of input configuration files and is used to
  create references between resources in that configuration.
- **id**: *Most* {{site.konnect_short_name}} resources have an `id` field which is a {{site.konnect_short_name}}
  assigned UUID. This field is not stored in declarative configuration files but
  will be used internally by the declarative engine.
- **name**: *Many* {{site.konnect_short_name}} resources have a `name` field which *may or may not*
  be subject to a unique constraint within an organization for that resource
  type.

Top-level resource keys and field names in declarative YAML are stable
configuration contract names. Use the names documented in the
[declarative resource reference](/kongctl/supported-resources/), and use
`ref` values when one resource needs to refer to another.

```yaml
application_auth_strategies:
  - ref: oauth-strategy
    name: "OAuth 2.0 Strategy"

portals:
  - ref: developer-portal
    name: "Developer Portal"
    default_application_auth_strategy_id: !ref oauth-strategy#id
```

## Basic structure

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

## Hierarchical vs flattened configuration

Parents are defined at the root of a configuration while children can be
expressed both nested under their parent and at the root with a parent reference
field.

### Hierarchical configuration

```yaml
apis:
  - ref: users-api
    name: "Users API"
    versions:
      - ref: v1
        version: "v1.0.0"
        spec: !file ./specs/users-v1.yaml
    publications:
      - ref: public
        portal_id: !ref main-portal
        visibility: public
```

### Flattened configuration

```yaml
apis:
  - ref: users-api
    name: "Users API"

api_versions:
  - ref: v1
    api: users-api
    version: "v1.0.0"
    spec: !file ./specs/users-v1.yaml

api_publications:
  - ref: public
    api: users-api
    portal_id: !ref main-portal
```

### Parent selectors and references

Fields such as `portal` on `portal_pages` and `api` on `api_versions` select the
parent declaration for a root-level child. They are kongctl configuration
fields. kongctl resolves the parent's {{site.konnect_short_name}} ID for API requests, including
route parameters. When a child is nested, its parent is inferred and the
selector can be omitted.

Fields such as `portal_id` on API publications are API relationship fields. The
flattened example uses `api: users-api` to select the owning API and
`portal_id: !ref main-portal` to reference the publication's target portal. A
plain ref such as `portal: portal-test` identifies a declaration's `ref`; it is
not a literal {{site.konnect_short_name}} UUID.

`portal: !ref portal-test` and `portal: !ref portal-test#id` are also valid
parent selectors. `!ref` defaults to `#id`, but affected releases require the
following workaround.

**Compatibility:** In affected releases, including v1.21.0, `!ref` on root-level
portal and API child parent selectors can silently omit children from plans. In
sync mode, this can schedule declared live children for deletion. Use a plain
parent ref, or nest the child under its parent, until you use a release
containing the fix for
[issue #2633](https://github.com/Kong/kongctl/issues/2633).
Continue using `!ref` for API relationship fields such as `portal_id`.

For example, manage a root-level page under an existing external portal using a
plain parent ref:

```yaml
portals:
  - ref: portal-test
    _external:
      selector:
        matchFields:
          name: "Docs Portal"

portal_pages:
  - ref: home
    portal: portal-test
    slug: /
    title: Home
    visibility: public
    status: published
    content: "# Welcome"
```

The external portal is not modified. Its declared page is managed normally.
Review `kongctl diff --mode sync -f config.yaml` before running sync and confirm
that declared pages are retained.

## Remote configuration files

You can also load a single configuration file from an HTTP or HTTPS URL:

```shell
kongctl apply -f https://get.konghq.com/example-kongctl.yaml
```

To save remote files locally and run the command from the saved copies in one
operation, use `--remote-file-save-dir` or its shorthand, `-s`:

```shell
kongctl apply \
  -f https://get.konghq.com/portal.yaml \
  -f https://get.konghq.com/api.yaml \
  --remote-file-save-dir ./kongctl-example
```

Remote files are saved into the directory using the filename from each URL path.
If multiple remote URLs would save to the same filename, the command fails
before fetching them. Existing files are left intact by default. Use
`--remote-file-save-force` or `-F` with `--remote-file-save-dir` to replace
existing saved files.

When `--remote-file-auth=auto` is enabled, which is the default, `kongctl` sends
the current profile's {{site.konnect_short_name}} bearer token only to HTTPS remote sources on
{{site.konnect_short_name}} hosts, such as `*.cloud.konghq.com` or the configured {{site.konnect_short_name}} API host.
Authentication is never sent to arbitrary hosts. Use `--remote-file-auth=none`
to fetch a remote file without adding {{site.konnect_short_name}} authentication headers.

Review remote configuration before running mutating commands in production.
Prefer HTTPS URLs and pin examples to immutable versions when using them in CI.

## Field validation

kongctl uses strict YAML validation to catch configuration errors early:

```yaml
# This will cause an error
portals:
  - ref: my-portal
    name: "My Portal"
    lables:  # ❌ ERROR: Unknown field 'lables'. Did you mean 'labels'?
      team: platform
```

Common field name errors:

- `lables` → `labels`
- `descriptin` → `description`
- `displayname` → `display_name`
- `strategytype` → `strategy_type`
