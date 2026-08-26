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
        Install [kongctl](/kongctl/) and [decK](/deck/). Pin reviewed versions
        in CI and use the same versions for local generation.
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
Give every managed root a `kongctl.namespace` through file defaults, then apply
with the exact namespace:

```sh
kongctl apply -f konnect/foundations.yaml \
  --require-namespace platform-foundations
```

## Bootstrap repository identities

Create one Konnect system account per service repository. Issue a token for each
account and store it as a protected repository secret. Account and token
creation are manual boundaries; do not store tokens in declarative files.

Use a second platform manifest to assign each existing account to its
organization team and grant:

- Catalog create, administer, and publish access;
- Gateway write access only to its team's development control plane; and
- read access needed to resolve shared Portals, auth strategies, and the
  production control plane.

Do not grant service identities production Gateway write access. KongAirlines
starts with broad organization-level API roles for simplicity and a scoped
development `Deployer` role. If `Deployer` cannot apply the required Service,
Route, and plugin entities, use the supported granular Gateway roles before
falling back to control-plane Admin.

Apply the access file after foundations exist. If role propagation causes the
first service run to fail, rerun it after propagation completes.

## Structure a service repository

Keep the mutable contract and retained releases beside the desired state:

```text
openapi.yaml
openapi/versions/<version>.yaml
konnect/dev.yaml
konnect/prod.yaml
gateway/dev/kong.yaml
gateway/prod/kong.yaml
gateway/plugins/ace.yaml
scripts/generate-gateway.sh
```

Only protected APIs need the ACE input. A deliberate production release copies
the OpenAPI document to `openapi/versions/<info.version>.yaml`; do not silently
replace older release inputs.

## Generate tagged Gateway state

Create a repository script that runs `deck file openapi2kong` with stable names
and IDs, adds `_info.select_tags`, and adds environment, team, owner, and
service-stage tags to every entity. If sibling APIs expose the same operational
path, such as `/health`, make their Gateway Routes unambiguous.

For protected APIs, add service-scoped ACE outside the OpenAPI document:

```yaml
_format_version: "1.0"
add-plugins:
  - selectors:
      - $.services[*]
    plugins:
      - name: ace
        config:
          match_policy: required
```

Run `deck file add-plugins`, then tag the plugin and validate the final state.
Commit the generated files. Pull-request CI must regenerate them without
credentials and fail if `git diff` reports drift.

## Declare service-owned Catalog state

Create a development kongctl manifest that:

- declares the development API, current version, and root OpenAPI spec;
- resolves the development Portal and team control plane with `!lookup` or an
  `_external` declaration;
- attaches `gateway/dev/kong.yaml` to the external control plane through
  `_deck`;
- creates a control-plane API implementation; and
- publishes privately.

For protected APIs, resolve the platform-owned development auth strategy by
name in `auth_strategy_ids`. Public APIs omit the field.

Create a production manifest with a separate API that uses retained release
specs, resolves the production Portal and control plane, publishes publicly,
and declares a control-plane implementation. Do not attach `_deck`; production
Gateway state belongs to the Platform Team.

## Apply development state

On a merge to `main`, run `kongctl apply` with the repository's Konnect token:

```sh
kongctl apply -f konnect/dev.yaml --base-dir . \
  --require-namespace <service>-dev
```

This applies only that service's tagged Gateway state and service-owned Catalog
resources. Keep credentialed deployment jobs separate from untrusted pull
request validation.

## Govern production Gateway changes

After a service release is merged, use a trusted workflow to open a PR in the
platform repository with an exact copy of `gateway/prod/kong.yaml`. Record the
source repository, source commit, SHA-256 checksum, decK version, and kongctl
version.

The platform production manifest attaches all promoted files to the production
control plane in one `_deck` block. Platform review and merge run one aggregate
apply:

```sh
kongctl apply -f konnect/production-gateway.yaml --base-dir .
```

Do not edit promoted files in the platform repository. Return required changes
to the owning service and promote a new artifact.

## Apply production Catalog state

After the production Gateway apply succeeds, manually dispatch the service's
production Catalog workflow from the exact promoted commit. Protect the job
with a production GitHub Environment and run:

```sh
kongctl apply -f konnect/prod.yaml --base-dir . \
  --require-namespace <service>-prod
```

This ordering ensures the governed runtime change exists before the service
publishes its production Catalog state.

## Understand v1 removal behavior

The initial architecture is apply-only. Removing YAML from Git does not delete
the remote resource. Treat removals as separately designed and reviewed
operations until your organization has an ownership-safe pruning process.
