---
title: Adapt patterns from KongAirlines
content_type: reference
layout: reference
description: Find useful API platform practices in the example repositories and adapt them to your organization.
products:
  - konnect-reference-platform
works_on:
  - konnect
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Explore KongAirlines
    url: /konnect-reference-platform/kong-air/
  - text: Follow an API change
    url: /konnect-reference-platform/apiops/
  - text: Design decisions and FAQ
    url: /konnect-reference-platform/faq/
---

Use KongAirlines as a collection of patterns, not a platform you must install
in full. You can explore the repositories without a Konnect account, deployment
credentials, or a running Gateway. Select a practice that solves a problem
you have, understand its boundaries, and adapt it to your own delivery platform.

The example uses [kongctl](/kongctl/) for Konnect resources, [decK](/deck/)
for Gateway configuration, and GitHub Actions for delivery. The practices are
not limited to the example's repository structure or CI system.

Start with [the repository map](/konnect-reference-platform/kong-air/) if you
are unfamiliar with the project. To understand the whole delivery sequence,
[follow an API change](/konnect-reference-platform/apiops/).

## Enable service-team self-service

**What it enables:** teams manage their APIs without asking a platform team
to deliver every change.

The platform repository declares shared resources and access assignments.
Service repositories manage their own Catalog APIs and resolve shared Portals
and control planes rather than declaring competing copies.

**Where to look:**

- [Platform foundations](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml): shared resources and team roles.
- [Repository access assignments](https://github.com/KongAirlines/platform/blob/main/konnect/access.yaml): automation identity membership.
- [Bookings development manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/dev.yaml): service-owned resources and references to shared infrastructure.

**Adapt:** the team boundaries, resource topology, and permissions to your
organization. The example's broad Catalog API roles are a starting point,
not a demonstration of isolation between every team's APIs.

**Preserve:** the distinction between referencing a shared resource and owning
it. Konnect RBAC authorizes access; declarative namespaces identify ownership.

## Make API-first delivery reviewable

**What it enables:** developers work on an API contract while reviewers see
the Gateway configuration that contract will produce.

CI generates and validates Gateway configuration from OpenAPI and explicit
transformation inputs. A separate workflow commits validated output to the
service PR and maintains a review comment.

**Where to look:**

- [Gateway generator](https://github.com/KongAirlines/bookings/blob/main/scripts/generate-gateway.sh): conversion and transformations.
- [PR validation](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/validate-konnect.yaml): credential-free generation and checks.
- [Artifact materialization](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/materialize-gateway.yaml): branch updates and review summaries.

**Adapt:** your contract linting, Gateway policies, conversion rules, and CI
provider. Keep intentional transformations as inputs instead of hand-editing
generated output.

**Preserve:** the boundary between untrusted PR validation and credentialed
automation. The write-capable workflow verifies the source commit and artifact
boundaries without executing PR-controlled scripts.

## Govern production without taking over API ownership

**What it enables:** the platform team governs changes in the production
traffic path while service teams retain control of their API lifecycle.

A service workflow opens a platform PR with the exact reviewed production
Gateway candidate and its provenance. Platform automation deploys the aggregate,
then triggers the service's production Catalog workflow from that source commit.

**Where to look:**

- [Service promotion](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/promote-prod.yaml): copying the candidate and recording its source.
- [Platform production workflow](https://github.com/KongAirlines/platform/blob/main/.github/workflows/apply-production-gateway.yaml): governed Gateway delivery and Catalog dispatch.
- [Service production Catalog workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/apply-prod-catalog.yaml): deployment with the service identity.

**Adapt:** your review policies, production topology, and approval process.
Not every organization needs a separate platform repository.

**Preserve:** the reviewed artifact and its source identity across the handoff.
Do not regenerate a different candidate after approval. Catalog access does not
require granting service automation production Gateway write access.

## Keep environments on one default branch

**What it enables:** development and production can evolve independently
without maintaining environment branches.

The example uses separate resources, files, and credentials for each stage.
Development Gateway writes are scoped to a service's tagged configuration.
Production Gateway state is reviewed and synchronized as a platform aggregate.

**Where to look:**

- [Development manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/dev.yaml) and [production manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/prod.yaml): explicit stage resources.
- [Gateway generator](https://github.com/KongAirlines/bookings/blob/main/scripts/generate-gateway.sh): environment and ownership tags.
- [Production aggregate](https://github.com/KongAirlines/platform/blob/main/konnect/production-gateway.yaml): the platform-owned synchronization boundary.

**Adapt:** the number of stages, control planes, and repositories.

**Preserve:** explicit reconciliation scopes. Independently synchronized stages
must not prune each other's resources. Namespaces and decK tags scope desired
state; they do not replace RBAC.

## Prepare releases without editing automation

**What it enables:** a team chooses a release through a reviewed PR instead
of changing version numbers inside deployment scripts.

The release workflow retains a stable contract, selects it for production,
and advances the root development contract. Generation reads that selection.
Older contracts stay available rather than being overwritten.

**Where to look:**

- [Release workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/release-api.yaml): release inputs and PR creation.
- [Release preparation](https://github.com/KongAirlines/bookings/blob/main/scripts/prepare-release.sh): file transformations and production selection.
- [Release validation](https://github.com/KongAirlines/bookings/blob/main/scripts/validate-api-releases.sh): checks for retained releases and version changes.

**Adapt:** your version conventions, compatibility checks, and retention policy.
The beta naming convention is an example choice, not a requirement of federation.

**Preserve:** the connection between the retained contract, production selector,
and generated candidate. Review the release and its deployment consequences
together.

## Connect delivery to developer onboarding

**What it enables:** API publication includes documentation, discovery, and an
application access process, not only Gateway routing.

The platform owns Portal content and application authentication strategies.
Services publish their APIs to those Portals. Flights and Destinations
demonstrate public access; Bookings and Customer demonstrate approved
application-key access.

**Where to look:**

- [Shared Portal content](https://github.com/KongAirlines/platform/tree/main/konnect/portal): pages, navigation, and reusable guide snippets.
- [Platform foundations](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml): Portals and application authentication strategies.
- [Bookings publication](https://github.com/KongAirlines/bookings/blob/main/konnect/prod.yaml): service-owned publication using a shared strategy.

**Adapt:** your audience, Portal visibility, approval process, and authentication
strategy. Read the [authentication decisions](/konnect-reference-platform/faq/#how-do-public-and-protected-apis-coexist)
before copying the protected-API policies.

**Preserve:** the distinction between documentation visibility and runtime
authorization. Application identity is not passenger identity. The example
service source uses fictional accounts; do not infer a deployed upstream's
behavior solely from the checked-in source.

## Start with one pattern

Choose a small outcome, such as showing generated Gateway differences in PRs.
Inspect its inputs, workflow, generated files, and trust boundaries. Implement
that practice in one repository and verify its behavior before extending it.
You do not need the complete KongAirlines topology or authentication design to
adopt that practice.

If you use a coding agent, give it the selected outcome, the linked example
files, and your existing repository constraints. Ask it to explain dependencies
and verification before proposing changes. The optional
[Reference Platform skill](https://github.com/Kong/ai-marketplace/tree/main/plugins/kong-konnect/skills/konnect-reference-platform)
provides additional guidance; your own manifests and policies remain the source
of truth.
