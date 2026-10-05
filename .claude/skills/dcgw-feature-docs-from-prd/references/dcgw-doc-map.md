# DCGW doc map

Reference for which file covers which DCGW topic, and the conventions for
each. Read this during Step 2/3 classification, before deciding which files
to touch.

## Contents

1. [Topic reference pages](#topic-reference-pages)
2. [The DCGW-wide reference page](#the-dcgw-wide-reference-page)
3. [Landing page](#landing-page)
4. [Index entry](#index-entry)
5. [Non-Terraform how-to conventions](#non-terraform-how-to-conventions)
6. ["Not supported" placeholder shapes](#not-supported-placeholder-shapes)

---

## Topic reference pages

All under `app/dedicated-cloud-gateways/`:

| Page | Covers |
|---|---|
| `network-architecture.md` | Overall network architecture, what to decide before deploying |
| `public-network.md` | Public network architecture, securing it |
| `private-network.md` | Private network architecture, connectivity options |
| `multi-cloud.md` | Multi-cloud deployment, hostname strategies |
| `transit-gateways.md` | AWS Transit Gateway attachment |
| `managed-cache.md` | Managed cache for Redis sizing/config/scaling |
| `production-readiness.md` | Production readiness checklist |
| `konnect-logs.md` | Data plane logs |

Pick the page by feature, not by guessing from the PRD title — a new AWS
peering variant goes in `transit-gateways.md` or a new/renamed page
alongside it, not folded into `network-architecture.md` by default.

A brand-new feature category with no existing topic page
needs a new page here. `managed-cache.md` is the precedent to model
structure on: a dedicated reference page, a `reference.md` blurb that links
to it (see below), and a landing page section.

---

## The DCGW-wide reference page

`app/dedicated-cloud-gateways/reference.md` is the catch-all reference page
and follows a size-driven mixed pattern — confirm which shape applies by
reading the page, don't default to one:

**Inline, full section** — for a small, self-contained feature with no
separate topic page. Examples already on the page: "CIDR size requirements"
(a single `{% include %}`), "Custom DNS" (two H3s, a table), "{{
site.base_gateway }} configuration" (a `{% kong_config_table %}` plus a
How-do-I H3). These live only here; there's no companion dedicated page.

**Short section that links out** — for a bigger feature that has its own
topic page. Examples: "Managed cache for Redis" (two sentences plus a link
to `managed-cache.md`), "Securing backend communication" (one intro
paragraph, then three H3s — AWS Transit Gateway, Azure VNet Peering, GCP VPC
Peering — each one sentence plus a link to that provider's dedicated page).
Don't repeat the dedicated page's content here; this section is a pointer,
not a summary.

When adding a new provider/kind to an existing feature (branch a), check
which shape that feature already uses on this page and match it — don't
introduce the other shape for one provider while the rest of the feature
uses the first.

---

## Landing page

`app/_landing_pages/dedicated-cloud-gateways.yaml`. Structured as `rows`,
each with an `h2` header and a row of `card` blocks, grouped by topic
(Networking, Name resolution, Managed cache for Redis, Network architecture,
More information). A new provider/kind (branch a) usually adds a CTA to an
existing card (e.g. a new `ctas` entry under the relevant provider's card). A
new feature category (branch b) usually adds a new `h2` row with its own set
of cards, modeled on the "Managed cache for Redis" row (a reference card plus
one card per provider).

---

## Index entry

`app/_indices/gateway.yaml` has a dedicated "Dedicated Cloud Gateways"
section (its own `items` list, separate from the catch-all
`/dedicated-cloud-gateways/**/*` glob that auto-includes everything under
the section for search/sitemap purposes). Curated entries there look like:

```yaml
- title: Custom plugin streaming
  description: Stream custom plugins from the control plane to the data plane.
  url: /dedicated-cloud-gateways/reference/#custom-plugins
```

Add an entry here for any page or `reference.md` section a reader should be
able to find from the Gateway docs index directly — minor FAQs
don't need one, follow precedent for what's already listed (provisioning, custom
plugin streaming, supported geos, upgrades, the Cloud Gateways API).

---

## Non-Terraform how-to conventions

Pass these to `how-to-starter` when scaffolding a non-Terraform DCGW how-to:

- `permalink: /dedicated-cloud-gateways/<slug>/`
- `breadcrumbs: [/dedicated-cloud-gateways/]`
- `products: [gateway]` or `[konnect]` (existing DCGW how-tos use both)
- `works_on: [konnect]` (DCGW only runs on Konnect)
- `tools:` omits `terraform` (that's the Terraform skill's job) — set to
  whatever the actual non-Terraform method is (`konnect-api`),
  per `how-to-starter`'s own tool-choice logic
- `automated_tests: false` is common for DCGW how-tos (provisioning is slow
  and account-specific) but isn't a hard rule — follow `how-to-starter`'s own
  judgment per guide
- Recommended `tags`: `dedicated-cloud-gateways`, the provider
  (`aws`/`azure`/`google-cloud`) if provider-specific, a feature tag
- Body conventions: a `{% konnect_api_request %}` or `{% control_plane_request %}`
  block for each API call, wrapped in `<!--vale off-->`/`<!--vale on-->`;
  reuse an existing prereq include (`prereqs/dedicated-cloud-gateways`, or a
  provider-specific one) rather than re-explaining setup inline; end with a
  Validate step, same hard convention as the Terraform how-tos.

For the full resource/attachment-kind vocabulary (needed when a non-Terraform
how-to covers the same feature a Terraform how-to also exists for, e.g. to
keep terminology consistent), see `dcgw-terraform-how-to`'s
`references/dcgw-terraform-patterns.md`.

---

## "Not supported" placeholder shapes

Real examples from `reference.md`'s FAQs, for the exact placeholder wording
to reuse when a provider/feature combination isn't supported:

> Can I use credential-less authentication (AWS workload identity or Azure
> managed identity) for Dedicated Cloud Gateways?
>
> You can use AWS workload identity with Dedicated Cloud Gateways. Azure
> managed identity isn't currently supported for Dedicated Cloud Gateways.

> Can I use the file system vault backend with Dedicated Cloud Gateways?
>
> No. The file system vault backend isn't supported on Dedicated Cloud
> Gateways because they don't provide access to the data plane's local
> filesystem for storing secret files.

The pattern: state plainly what isn't supported, then (when there's a real
reason) the concrete technical reason why — not a vague "not yet available."
Never invent the reason if the PRD/spec doesn't give one; a bare "isn't
currently supported" is better than a fabricated explanation.
