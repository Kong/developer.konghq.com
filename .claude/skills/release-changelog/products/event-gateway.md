# Profile: Kong Event Gateway (`event-gateway`)

- Product name in headings: `Kong Event Gateway`
- Liquid variables in titles: `{{site.event_gateway}}` = Kong Event Gateway, `{{site.event_gateway_short}}` = Event Gateway. Defined in `jekyll.yml` (`event_gateway`, `event_gateway_short`).
- Output file: `docs/release-changelog/event-gateway/{VERSION}.md` (e.g. `event-gateway/1.3.md`)
- Typical release branch: `release/event-gateway-{VERSION}`, diffed against `origin/main`.

## Path filters

Keep only these paths (after the baseline exclusions):

```
app/event-gateway/
app/_event_gateway_policies/
app/_how-tos/event-gateway/
app/_references/event-gateway/
app/_landing_pages/event-gateway.yaml
app/_indices/event-gateway.yaml
```

Also keep other pages that changed only if their frontmatter has `event-gateway` under `products` or `tags`, or the diff clearly adds Event Gateway content (e.g. `app/kongctl/supported-resources.md`, `app/gateway/plugins/expressions.md`). Files that only changed incidentally (shared how-to test tooling, other products' pages) are left out. Skip `app/_data/` (bootstrap schema, product release list) because those are not reader-facing pages.

## URL derivation (when `permalink` is missing)

- `app/_how-tos/event-gateway/foo.md` -> has an explicit `permalink` of the form `/event-gateway/foo/`. Event Gateway how-tos are NOT under `/how-to/`. Always read the `permalink`.
- `app/_event_gateway_policies/foo/index.md` -> `/event-gateway/policies/foo/`
- `app/_event_gateway_policies/foo/index.md` reference tab -> `/event-gateway/policies/foo/reference/` (do not list separately, it is the same page)
- `app/_event_gateway_policies/foo/examples/bar.yml` -> `/event-gateway/policies/foo/examples/bar/`
- `app/event-gateway/foo.md` -> `/event-gateway/foo/`
- `app/event-gateway/entities/foo.md` -> `/event-gateway/entities/foo/`
- `app/_references/event-gateway/{VERSION}/headers.md` -> `/event-gateway/headers/`
- `app/_references/event-gateway/{VERSION}/metrics.md` -> `/event-gateway/metrics/` (older versions: `/event-gateway/metrics/{VERSION}/`)
- `app/_landing_pages/event-gateway.yaml` -> `/event-gateway/`

Policy example `.yml` files have no frontmatter. Read `title` and `description` from the top-level YAML. Policy `index.md` files use `name` as the display name.

## Grouping rules

Group by capability, not by file type. Group policies with their related how-tos and examples. Suggested groups (use only those that have content):

- **Policies, one group per category**: use the policy `categories` frontmatter value as the group heading, with the display name from `app/_data/event_gateway_policy_categories.yml` (Security, Traffic Control, Transformations, Data Quality). Each policy goes under its category. Examples go under their policy. Guides that centre on a policy go under that policy's category. Within a category, use a bold sub-heading per policy or policy family (e.g. **Mask Fields policies:**). Categories with no changes are omitted. Read `categories` from each policy `index.md`, do not guess.
- **Authentication and authorization**: mTLS, SASL, Kong Identity, SNI routing how-tos (ACLs and `tls-server` are policies, so they go under their policy category)
- **Expressions (CEL)**: `event-gateway/expressions.md` and expression-related examples
- **Entities**: `event-gateway/entities/`
- **Observability**: metrics reference, OpenTelemetry how-tos
- **Getting started and deployment**: get started, image signature verification, quickstart-style how-tos
- **References**: headers, metrics, configuration

If a policy has both new `index.md` and new examples, list the policy page first, then its examples as sub-bullets.

## Special pages

- Breaking changes: `app/event-gateway/breaking-changes.md` -> `## Changes` section, only if it changed.
- Also mention `known-limitations`, `upgrade`, and `version-support-policy` under Updated docs when they changed.
- `app/event-gateway/changelog.md` is the product changelog page. List it under Updated docs if it changed.

## Auto-generated references

`app/_references/event-gateway/{VERSION}/headers.md` and `metrics.md` are auto-generated (the file header says so). On a new release they appear as new files. Do not list them individually under New docs. Collapse to:

```
_Auto-generated references updated: [Event Gateway headers](URL), [Event Gateway metrics](URL)_
```

Bootstrap schema JSON under `app/_data/event-gateway-bootstrap-schema/` is also auto-generated and not reader-facing, so omit it.
