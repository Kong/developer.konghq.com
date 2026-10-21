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
```

Also keep other pages that changed only if their frontmatter has `event-gateway` under `products` or `tags`, or the diff clearly adds Event Gateway content (e.g. `app/kongctl/supported-resources.md`, `app/gateway/plugins/expressions.md`). Files that only changed incidentally (shared how-to test tooling, other products' pages) are left out. Skip `app/_data/`, except the bootstrap schema (see Special pages).

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

## Special pages

Handle these before grouping. They are not placed by the grouping rules.

- **Breaking changes**: `app/event-gateway/breaking-changes.md` goes under `## Changes`, only if it changed.
- **Auto-generated references**: `app/_references/event-gateway/{VERSION}/headers.md` and `metrics.md` are auto-generated. On a new release they appear as new files. Do not list them individually.
- **Configuration reference**: `app/_data/event-gateway-bootstrap-schema/{VERSION}.json` renders into `/event-gateway/configuration/`. Do not list the JSON file. If `app/event-gateway/configuration.md` itself was edited, list it under References with an annotation. Otherwise it appears only on the collapsed line.

Collapse the auto-generated pages into one line at the bottom of the output:

```
_Auto-generated references updated: [Event Gateway configuration reference](URL), [Event Gateway headers](URL), [Event Gateway metrics](URL)_
```

Include only the pages that actually changed.

## Grouping rules

Group by capability, not by file type. Group policies with their related how-tos and examples. Use only groups that have content:

- **Policies, one group per category**: use the policy `categories` frontmatter value as the group heading, with the display name from `app/_data/event_gateway_policy_categories.yml` (Security, Traffic Control, Transformations, Data Quality). Each policy goes under its category. Examples go under their policy. Guides that centre on a policy go under that policy's category. Within a category, use a bold sub-heading per policy or policy family (e.g. **Mask Fields policies:**). Categories with no changes are omitted. Read `categories` from each policy `index.md`, do not guess.
- **Authentication and authorization**: mTLS, SASL, Kong Identity, SNI routing how-tos (ACLs and `tls-server` are policies, so they go under their policy category)
- **Entities**: `app/event-gateway/entities/`
- **Observability**: OpenTelemetry how-tos
- **Getting started and deployment**: get started, image signature verification, quickstart-style how-tos
- **References**: every remaining page under `app/event-gateway/*.md` (for example expressions, architecture, upgrade, known limitations, version support policy, changelog)

If a policy has both new `index.md` and new examples, list the policy page first, then its examples as sub-bullets.
