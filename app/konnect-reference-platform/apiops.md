---
title: Federated APIOps
content_type: reference
layout: reference
products:
  - konnect-reference-platform
description: How service and platform teams deliver APIs with kongctl and decK.
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: KongAirlines implementation
    url: /konnect-reference-platform/kong-air/
  - text: Adopt the architecture
    url: /konnect-reference-platform/how-to/
  - text: Frequently asked questions
    url: /konnect-reference-platform/faq/
---

[APIOps](/deck/apiops/) applies version control, review, automation, and
declarative configuration to the API lifecycle. The Reference Platform uses a
federated model: desired state remains with the team that owns the resource,
and each repository invokes supported tooling directly.

## Sources of truth

There are no environment branches and no separate service registry.

- OpenAPI documents describe API contracts.
- kongctl manifests describe Konnect Catalog and shared platform resources.
- Committed, CI-generated decK manifests describe {{site.base_gateway}}
  runtime entities and record the exact reviewed deployment state.
- `main` contains separate development and production resources and files.

In a service repository, the root `openapi.yaml` is always a beta development
contract. `openapi/versions/` retains immutable stable contracts, and the
API-level `version` in `konnect/prod.yaml` selects the current production
contract. The generator derives its production input from that selector.

Service repositories own their development and production Catalog APIs,
versions, specifications, publications, and control-plane implementations.
They also own development Gateway configuration. The platform repository owns
shared foundations and the production Gateway aggregate. Development uses the
service namespace, while the separately approved production Catalog workflow
uses `<service>-prod`; this prevents either synchronization from pruning the
other stage's API.

## Generate Gateway state

Each service repository has a deterministic generation script. It performs the
following operations with a pinned decK version:

1. `deck file openapi2kong` converts the selected OpenAPI document.
2. `deck file patch` adds `_info.select_tags` for ownership-safe synchronization.
3. `deck file add-tags` ensures Services, Routes, and service-scoped plugins
   carry environment, team, owner, and service-stage tags.
4. `deck file validate` checks each materialized result before delivery.

Development files select a unique service-stage tag so sibling repositories can
synchronize safely against a shared team control plane. Production files select
the common `env-prod` tag and are synchronized together by the Platform Team.
Public OpenAPI contracts exclude internal operational endpoints such as health,
readiness, and liveness checks.

Advance the development contract's `info.version` whenever its contents
change. Konnect treats the version as the Catalog API version identity, and
[ACE](/plugins/ace/) prevents removing operations by modifying the current
version in place.
Treat development API versions as append-only: put the current version in a
separate `konnect/dev-versions.yaml` manifest and deliver it with `kongctl
apply`. Omit the `versions` collection from the synchronized `dev.yaml` so
older versions are not interpreted as stale and deleted.

Pull-request validation generates and validates both files without Konnect
credentials and uploads them as an artifact. A trusted workflow that never
executes PR-controlled code verifies the current PR head and artifact
boundaries, then uses the repository GitHub App to commit the files to a
same-repository branch. The App commit triggers validation again; when the
files match, no further commit is made. Fork code never receives a Konnect or
repository-write credential. The workflow maintains one PR comment with the
changed inputs and generated Gateway diff summaries, updating it after every
validated change rather than replacing the PR author's description.

Generated files are automation-owned. Teams represent additional Gateway
behavior as reviewed generator or patch inputs, allowing reviewers to inspect
both the intent and resulting Gateway diff. Validation also verifies the
development beta, production selector, retained version declarations, spec
filenames, and release immutability.

## Prepare a release

A manually dispatched service workflow accepts two stable versions: the
version to release and the next version to develop. If `openapi.yaml` is
`0.2.0-beta.N`, inputs `0.2.0` and `0.3.0` open a service PR that:

1. creates the immutable `openapi/versions/0.2.0.yaml` snapshot;
2. retains all prior versions and sets the production API's current version to
   `0.2.0` in `konnect/prod.yaml`;
3. advances the root document to `0.3.0-beta.1`; and
4. materializes and validates both Gateway stages in the release PR.

The workflow refuses to overwrite an existing release. Humans review and merge
its PR; automation does not write release state directly to `main`.

## Development delivery

After a service change reaches `main`, the repository runs:

```sh
./scripts/generate-gateway.sh
git diff --exit-code -- gateway/dev/kong.yaml gateway/prod/kong.yaml
kongctl apply -f konnect/dev-versions.yaml --base-dir . \
  --auto-approve
# APIs linked to an ACE-enabled control plane, until kongctl #2510 is resolved:
./scripts/transition-ace-api-version.sh "<development-api-name>"
kongctl sync -f konnect/dev.yaml --base-dir . \
  --require-namespace <service>
```

For APIs linked to an ACE-enabled control plane, the transition helper verifies
that the additive apply created the child version, then selects it using the
Konnect API's explicit `force=true` behavior. This includes public APIs that do
not select an application-auth strategy because their control-plane
implementations remain governed by ACE. This is a temporary workaround for
[kongctl #2510](https://github.com/Kong/kongctl/issues/2510); remove it when
kongctl can declaratively order and authorize ACE-governed transitions.
The additive apply temporarily omits `--require-namespace` because kongctl
1.20.2 loses namespace defaults for external-only sources. Restore the guard
after [kongctl #2503](https://github.com/Kong/kongctl/pull/2503) is released;
the manifest continues to declare its service namespace.

The manifest uses `_external` and `!lookup` to resolve the Platform Team-owned
development control plane and Portal. `_deck` makes kongctl run one decK synchronization
for that service's tagged Gateway state. The final sync manages the
service-owned private Catalog API, its publication, its control-plane
implementation, and tagged Gateway state without deleting API version history.

Each repository uses a dedicated Konnect system account token. kongctl
namespaces define declarative ownership; Konnect RBAC defines what that identity
can actually change. Sibling repositories can run at the same time in v1. Their
unique names and decK select tags ensure each synchronization can delete only
the Gateway entities owned by that service.

## Production promotion

Production uses an explicit ownership boundary:

1. The release workflow opens a service PR containing the stable contract,
   next development beta, and updated production selector.
2. After that PR merges, a trusted workflow copies the exact reviewed candidate
   into `KongAirlines/platform` and opens a PR.
3. The platform PR records the source repository, commit, SHA-256 checksum,
   decK version, and kongctl version.
4. The Platform Team reviews and merges the Gateway change.
5. The platform workflow synchronizes all four production files in one kongctl
   `_deck` operation against `kongairlines-prod`.
6. After the Gateway synchronization succeeds, the platform workflow reads
   the changed provenance and dispatches the owning service's production
   Catalog workflow with the exact promoted commit.
7. The Service Team approves its protected GitHub Environment, and the
   service-owned identity synchronizes the Catalog state.

<!--vale off -->
{% mermaid %}
sequenceDiagram
  participant S as Service repository
  participant P as Platform repository
  participant G as Production Gateway
  participant C as Konnect Catalog
  S->>S: Review release PR and retain stable contract
  S->>P: Open promotion PR with provenance
  P->>P: Platform review
  P->>G: Aggregate kongctl sync with _deck
  P->>S: Dispatch Catalog sync from provenance
  S->>C: Approved kongctl sync from promoted commit
{% endmermaid %}
<!--vale on -->

The platform copy is the production Gateway source of truth. Do not hand-edit
it. Make corrections in the service repository and promote a new exact copy.
Rollback follows the same reviewed PR process using retained release inputs.
Namespaces and decK select tags scope synchronization, including deletions, to
the declarative owner.

## Authentication flow

Bookings and Customer Information publish with separate platform-owned
development and production Key Auth strategies. The Platform repository
installs ACE globally on every control plane with `match_policy: required`.
Because every Catalog API links to a control plane, ACE uses each OpenAPI
document's operations for access decisions independently from the Gateway Route
layout. Destinations and Flights publish without auth strategies, so their
matched operations remain anonymous.
