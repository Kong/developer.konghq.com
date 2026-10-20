---
title: Adopt the {{site.konnect_short_name}} Reference Platform architecture
content_type: how_to
permalink: /konnect-reference-platform/how-to/
description: Build a federated kongctl and decK delivery model in your repositories.
products:
  - konnect-reference-platform
works_on:
  - konnect
tldr:
  q: How do I adopt the {{site.konnect_short_name}} Reference Platform?
  a: Define platform and service ownership, author direct kongctl and decK desired state, and use repository-specific identities for federated delivery.
tags:
  - reference-platform
prereqs:
  show_works_on: false
  expand_accordion: false
  inline:
    - title: Konnect organization
      content: |
        You need a {{site.konnect_saas}} organization where you can create
        control planes, Developer Portals, application auth strategies,
        organization teams, system accounts, and role assignments.
    - title: Git repositories and CI/CD
      content: |
        You need a Platform Team repository and one or more service
        repositories. The examples use GitHub Actions, but the ownership model
        applies to other CI/CD systems.
    - title: Supported command-line tools
      content: |
        Install [kongctl](/kongctl/) and [decK](/deck/). The example tracks the
        latest stable kongctl release in CI so compatibility regressions are
        visible, while generation uses a reviewed decK version.
automated_tests: false
---

This guide creates the ownership boundaries shown by the
[KongAirlines implementation](https://github.com/KongAirlines). It does not
install a product or generate repositories. Adapt the checked-in manifests and
workflows to your names, topology, and governance requirements.

## Define the topology and owners

Choose a Platform Team repository and identify the Service Team repositories.
Record which team owns each API. Start with:

- one development control plane per service team;
- one Platform Team-governed production control plane;
- separate development and production Developer Portals; and
- separate development and production application auth strategies.

Keep both stages on `main` as separate resources and files. Do not introduce an
environment branch or a registry that duplicates kongctl desired state.

## Declare shared foundations

In the platform repository, create a direct kongctl manifest containing:

- organization teams;
- development and production control planes;
- development and production Portals; and
- the application auth strategies used by protected APIs.

The KongAirlines example is
[`konnect/foundations.yaml`](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml).
Give every managed root a `kongctl.namespace` through file defaults, then synchronize
with the exact namespace:

```sh
kongctl sync -f konnect/foundations.yaml \
  --require-namespace platform
```

## Bootstrap repository identities

Create a dedicated Platform automation system account manually, grant it
Organization Admin access, and store its token as `KONNECT_TOKEN` in a
protected production environment in the platform repository. This identity
synchronizes the shared foundations and production Gateway aggregate.

Create one Konnect system account per service repository manually. Use a second
platform manifest to assign each existing account to its service team. Synchronize
this file after the foundations exist so the accounts inherit the role set
owned by the Platform Team. Team membership remains platform desired state.

Issue a token for each account and store it as `KONNECT_TOKEN` in that service
repository's development and protected production environments. Account and
token creation and secret placement are manual boundaries; do not store tokens
in declarative files.

Grant each service team:

- Catalog create, administer, and publish access;
- Gateway write access only to its team's development control plane; and
- read access needed to resolve shared Portals, auth strategies, and the
  production control plane.

Do not grant service identities production Gateway write access. KongAirlines
starts with broad organization-level API roles for simplicity and a scoped
development `Deployer` role. If `Deployer` cannot apply the required Service,
Route, and plugin entities, use the supported granular Gateway roles before
falling back to control-plane Admin.

If role propagation causes the first service run to fail, rerun it after
propagation completes.

## Structure a service repository

Keep the mutable contract and retained releases beside the desired state:

```text
openapi.yaml
openapi/versions/<version>.yaml
konnect/dev.yaml
konnect/prod.yaml
gateway/dev/kong.yaml
gateway/prod/kong.yaml
scripts/generate-gateway.sh
scripts/prepare-release.sh
scripts/validate-api-releases.sh
.github/workflows/materialize-gateway.yaml
.github/workflows/release-api.yaml
```

Keep `openapi.yaml` on the next beta version and keep stable contracts in
`openapi/versions/`. Set the production API's top-level `version` in
`konnect/prod.yaml` to the stable release that production generation and
Catalog synchronization must use. Never replace an older release input.

## Generate tagged Gateway state in CI

Create a repository script that runs `deck file openapi2kong` with stable names
and IDs, adds `_info.select_tags`, and adds environment, team, owner, and
service-stage tags to every entity. Treat the OpenAPI document as the
client-facing contract; exclude internal health, readiness, and liveness
operations that clients can't reach through the Gateway.

In the platform repository, define [ACE](/plugins/ace/) as global control-plane
state outside the service OpenAPI documents:

```yaml
_format_version: "3.0"
_info:
  select_tags:
    - scope-platform-ace-dev
consumers:
  - username: kongairlines-anonymous
    tags:
      - env-dev
      - owner-platform
      - scope-platform-ace-dev
plugins:
  - name: ace
    config:
      match_policy: required
      anonymous: kongairlines-anonymous
    tags:
      - env-dev
      - owner-platform
      - scope-platform-ace-dev
```

Apply one global ACE instance to each control plane before creating Catalog
control-plane implementations. With `match_policy: required`, every request
must match an operation from an API published through that control plane.
The Platform Team declares one Key Auth application authentication strategy
per deployment stage, using `X-API-Key` as its credential header. Protected
API publications select that strategy. Developers use Dev Portal to create
applications, request API access, and generate keys after approval. This flow
does not require an external identity provider.

The anonymous Consumer lets public operations proceed without credentials.
On protected operations, a service-owned post-function runs after ACE and
rejects the anonymous Consumer or a request without ACE's authenticated
application ID. The example applies this guard to the Bookings and Customer
Gateway Services; for a Service with mixed access, scope the guard to its
protected Routes instead. OpenAPI security declarations describe the contract;
the generation pipeline must also produce the matching runtime policies.

The guard uses Gateway 3.16's `kong.ctx.shared.ace.application_id` to set
`X-KongAir-Account-ID`, replacing any client-supplied account header. It removes
`X-Consumer-Username` and the API key before proxying. See the
[Bookings generator input](https://github.com/KongAirlines/bookings/blob/main/gateway/application-auth.yaml)
for the complete policy. Validate this ACE context integration when upgrading
Gateway.

Bookings and Customer use the same immutable application ID to select an
isolated synthetic demo account. It represents the consuming application, not
a logged-in passenger. Upstream services must only be reachable through the
trusted Gateway boundary.

Do not require service developers to generate decK output manually.
Credential-free pull-request CI generates and validates both stages, then
uploads only the two generated files. A separate trusted workflow verifies the
artifact came from the current head of a same-repository PR, validates its file
boundaries, and commits it back to that branch. The resulting PR contains the
actual Gateway state reviewers are approving. A second validation run proves
that committed state matches deterministic generation and prevents a commit
loop. The trusted workflow also maintains a PR comment that summarizes the
changed inputs and expands to show the generated development and production
Gateway diffs.

Keep generated files automation-owned. Express intentional differences from
the OpenAPI conversion as reviewed generator or patch inputs rather than
editing generated output. Validation must also require a beta root version,
require `info.version` to advance whenever that contract changes, validate
stable files against their filenames and production declaration, and
reject modification or deletion of releases already present on the target
branch. Pull requests from forks do not receive the write credential;
contributors can commit generated output themselves or a maintainer can move
the change to a trusted same-repository branch.

## Automate release preparation

Add a manually dispatched workflow that accepts a stable release version and
the next development version. It should run a repository script that:

1. verifies that the root beta corresponds to the requested stable release;
2. refuses to overwrite an existing versioned file;
3. creates the stable snapshot and adds it to the production manifest;
4. updates the production API's top-level current version;
5. advances the root contract to the next `-beta.1` version; and
6. materializes and validates development and production Gateway state in the
   release PR.

Have the workflow open a service PR rather than commit to `main`. This keeps
the release, next development contract, and Catalog selector in one review.
Use a trusted GitHub credential that can push the
release branch and open the service PR so the resulting event triggers normal
pull-request validation; the default GitHub Actions token does not do so.

## Declare service-owned Catalog state

Create a development kongctl manifest that:

- declares the development API, current version, and root OpenAPI spec;
- resolves the development Portal and team control plane with `!lookup` or an
  `_external` declaration;
- attaches the committed, CI-generated `gateway/dev/kong.yaml` to the external control
  plane through `_deck`;
- creates a control-plane API implementation; and
- publishes privately.

For protected APIs, select the platform-owned Key Auth strategy explicitly:

```yaml
auth_strategy_ids:
  - !lookup {name: kongairlines-key-auth-dev}
```

The production publication selects `kongairlines-key-auth-prod`. Public
Flights and Destinations remain anonymous. Portal visibility controls
documentation access separately from runtime application authorization.

Create a production manifest with a separate API that uses retained release
specs, resolves the production Portal and control plane, publishes publicly,
and declares a control-plane implementation. Do not attach `_deck`; production
Gateway state belongs to the Platform Team. Give the production Catalog API a
separate `<service>-prod` namespace because development and production are
synchronized by independently approved workflows.

## Synchronize development state

On a merge to `main`, regenerate only to prove the reviewed files are current,
add the new API version, select it, and then synchronize the remaining state
with the repository's Konnect token:

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

Treat Catalog API versions as append-only. The apply manifest contains only
the version being added, while the sync manifest omits `versions` so it cannot
delete prior versions. For APIs linked to an ACE-enabled control plane, the
transition helper is a temporary workaround for
[kongctl #2510](https://github.com/Kong/kongctl/issues/2510): it selects the
already-created version with the Konnect API's explicit `force=true` behavior.
This includes public APIs without an application-auth strategy because their
control-plane implementations are still governed by global ACE policy.
The additive apply temporarily omits `--require-namespace` because kongctl
1.20.2 loses namespace defaults for external-only sources. Restore the guard
after [kongctl #2503](https://github.com/Kong/kongctl/pull/2503) is released;
the manifest still declares its service namespace throughout.
The final sync reconciles creates, updates, and deletions for the service's
other namespaced Catalog resources and tagged Gateway state. Keep credentialed
deployment jobs separate from untrusted pull-request validation.

## Govern production Gateway changes

After a service release is merged, use a trusted workflow to copy the reviewed
`gateway/prod/kong.yaml` into a PR in the platform repository. Do not
regenerate it after service review. Record the source repository, source
commit, SHA-256 checksum, decK version, and kongctl version.

The platform production manifest attaches all promoted files to the production
control plane in one `_deck` block. Platform review and merge run one aggregate
synchronization from a protected production environment:

```sh
kongctl sync -f konnect/production-gateway.yaml --base-dir . \
  --auto-approve
```

The manifest still declares the `platform` namespace. Until
[kongctl #2503](https://github.com/Kong/kongctl/pull/2503) is available in a
release, omit `--require-namespace` for this external-control-plane `_deck`
operation because kongctl 1.20.2 loses the file-level namespace default during
planning. Restore the guard after upgrading to a release that contains the
fix.

Do not edit promoted files in the platform repository. Return required changes
to the owning service and promote a new artifact.

## Synchronize production Catalog state

After the production Gateway synchronization succeeds, have the platform
workflow read each changed provenance file and dispatch the owning service's
production Catalog workflow with the exact promoted commit. Use a narrowly
scoped GitHub App token for the cross-repository dispatch. Keep the service job
behind its own production GitHub Environment so the Service Team approves the
Catalog publication using its repository's Konnect identity:

```sh
kongctl sync -f konnect/prod.yaml --base-dir . \
  --require-namespace <service>-prod
```

The service workflow verifies that it checked out the requested commit before
running kongctl. This ordering ensures the governed runtime change exists
before the service publishes its production Catalog state. Keep manual
workflow dispatch available as an explicit recovery path, not the normal
release process.

## Scope deletion safely

`kongctl sync` reconciles removals as well as creates and updates. Require the
owning kongctl namespace on every run. For shared control planes, give every
generated decK file a unique `_info.select_tags` value and apply matching tags
to every owned entity. The platform production aggregate uses one shared
`env-prod` selection because it synchronizes all reviewed service candidates
together. Review deletion plans with the same care as additions.

## Validate the delivery boundaries

After implementing the workflows, verify the ownership model with one service
before onboarding the others:

1. Synchronize the platform foundations and confirm that the shared control planes,
   Portals, Key Auth strategies, the anonymous Consumer, teams, and repository system accounts exist.
2. Merge a service change and confirm that its development workflow updates
   only that service's Catalog and tagged Gateway state.
3. Prepare and merge a release, then confirm that automation opens a platform
   promotion PR containing the exact production Gateway artifact and its
   provenance.
4. Approve the platform production job and confirm that the aggregate Gateway
   configuration is synchronized before approving the service's production Catalog
   job.
5. Register a test application, obtain approval, and generate its API key.
   Through a running Gateway, confirm Flights and Destinations work without
   credentials and protected APIs reject missing, invalid, or unregistered
   application keys. Verify approved applications receive distinct demo accounts,
   cannot read another application's bookings, and cannot forge account headers.
   Rotate a key and confirm the application account remains unchanged.
