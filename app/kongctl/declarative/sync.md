---
title: "Sync scope and deletion safety with kongctl"
description: "Understand omissions, empty collections, singletons, and deletion scope."
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

Read this page before reconciling partial manifests, empty collections, or
children of external parents. Use apply mode when you only intend creates and
updates.

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
  `custom_domain: {}` deletes any existing managed custom domain for that portal
  during sync. `null` is rejected because sync does not infer reset or delete
  semantics from null. Update-only singleton sections, such as `customization`,
  cannot be deleted by declaring `{}`.
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

Defaults on an external-only file satisfy namespace guardrails without adding
managed-parent deletion scope. A defaults-only file still selects namespaces for
sync deletion. See [namespace
guardrails](/kongctl/declarative/ownership/#namespace-enforcement-flags).

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
kongctl plan --mode sync -f config.yaml --output-file plan.json
kongctl sync --plan plan.json
```
