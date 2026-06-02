---
title: kongctl sync
description: Synchronize configurations using kongctl.

content_type: reference
layout: reference

works_on:
  - konnect

tools:
  - kongctl

breadcrumbs:
  - /kongctl/

related_resources:
  - text: Declarative configuration with kongctl
    url: /kongctl/declarative/
  - text: Get started with kongctl
    url: /kongctl/get-started/
---

The `sync` command applies your configuration as the full desired state, creating and updating resources and deleting managed resources that are missing from explicitly scoped collections.

If you want to apply configuration without deleting resources (creates and updates only), use [`kongctl apply`](/kongctl/apply/) instead.

## How kongctl sync works

Sync scope is based on YAML key presence:

- Omitted resource collections are ignored.
- Explicit empty root lists mean the desired count is zero. For example,
  `apis: []` deletes managed APIs in the selected namespace.
- Parent and child collections are scoped separately. A `portal` block without
  `pages` doesn't delete {{site.dev_portal}} pages. Use `pages: []` under that `portal` block to
  declare that the {{site.dev_portal}} should have no pages.
- Map-shaped child collections use an empty object as the empty collection. For
  example, `email_templates: {}` means the {{site.dev_portal}} should have no customized
  email templates.
- Singleton child sections use the same key-presence rule, but `{}` and `null`
  are intentionally different. Omit a singleton key to ignore that child.
  Provide an object with fields to manage or update it. For optional,
  delete-capable {{site.dev_portal}} singletons such as `custom_domain`, `email_config`, and
  `audit_log_webhook`, an empty object scopes the child with desired count zero:
  `custom_domain: {}` deletes any existing managed custom domain for that
  {{site.dev_portal}} during sync. `null` is rejected because sync doesn't infer reset or
  delete semantics from null. Update-only singleton sections, such as
  `customization`, cannot be deleted by declaring `{}`.
- Empty child collections must be nested under a parent resource. Root-level
  `api_documents: []` is rejected because it doesn't identify which API owns
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

## Examples 

Preview sync changes:

```shell
kongctl sync -f config.yaml --dry-run
```

Sync configuration with a prompt confirmation:

```shell
kongctl sync -f team-config.yaml
```

Skip confirmation prompt and sync changes without approval:

{:.warning}
> Be careful when using the `--auto-approve` flag, as this command will create, update, and delete entities without any preview or confirmation.

```shell
kongctl sync -f config.yaml --auto-approve
```

Sync from a plan artifact:

```shell
kongctl sync --plan plan.json
```

## Subcommands

kongctl provides the following tools for syncing configuration:

{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: |
      [kongctl sync konnect](/kongctl/sync/konnect/)
    description: "Synchronize with {{site.konnect_short_name}}."
{% endtable %}

## Command usage

{% include_cached /kongctl/help/sync/index.md %}
