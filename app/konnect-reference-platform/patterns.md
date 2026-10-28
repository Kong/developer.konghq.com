---
title: Adapt patterns from KongAirlines
content_type: reference
layout: reference
description: Find useful API platform practices in the KongAirlines example repositories and adapt them to your organization. Each pattern lists where to look, what to adapt, and what to keep.
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

KongAirlines is a collection of patterns that you adopt one at a time.
You don't need to install the whole platform.
You can explore the repositories without a {{site.konnect_short_name}} account, deployment credentials, or a running Gateway.
Select a practice that solves a problem you have, learn its boundaries, and adapt it to your own delivery platform.

The example uses [kongctl](/kongctl/) for {{site.konnect_short_name}} resources, [decK](/deck/) for Gateway configuration, and GitHub Actions for delivery.
The practices work with other repository structures and other CI systems.

If you are new to the project, start with [the repository map](/konnect-reference-platform/kong-air/).
To see the whole delivery sequence, [follow an API change](/konnect-reference-platform/apiops/).

## Enable service-team self-service

What it enables: teams manage their APIs and the platform team doesn't deliver every change.

The platform repository declares shared resources and access assignments.
Service repositories manage their own [Catalog](/catalog/) APIs.
They use the shared [Dev Portals](/dev-portal/) and control planes and don't declare duplicate copies.

Where to look:

- [Platform foundations](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml): shared resources and team roles.
- [Repository access assignments](https://github.com/KongAirlines/platform/blob/main/konnect/access.yaml): automation identity membership.
- [Bookings development manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/dev.yaml): service-owned resources and references to shared infrastructure.

Adapt: the team boundaries, the resource topology, and the permissions to your organization.
The broad Catalog API roles in the example are a starting point.
They don't isolate the APIs of one team from another.

Keep: the difference between a reference to a shared resource and ownership of it.
{{site.konnect_short_name}} RBAC authorizes access.
Declarative namespaces identify ownership.

## Make API-first delivery reviewable

What it enables: developers work on an API contract, and reviewers see the Gateway configuration that the contract produces.

CI generates and tests Gateway configuration from OpenAPI and from explicit transformation inputs.
A separate workflow commits the tested output to the service PR and maintains a review comment.

Where to look:

- [Gateway generator](https://github.com/KongAirlines/bookings/blob/main/scripts/generate-gateway.sh): conversion and transformations.
- [PR validation](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/validate-konnect.yaml): generation and tests without credentials.
- [Artifact materialization](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/materialize-gateway.yaml): branch updates and review summaries.

Adapt: your contract linting, your Gateway policies, your conversion rules, and your CI provider.
Keep intentional transformations as inputs and don't edit the generated output by hand.

Keep: the boundary between PR validation that's untrusted and automation that has credentials.
The workflow that can write makes sure that the source commit and the artifact boundaries are correct.
It doesn't run scripts that the PR controls.

## Govern production without taking over API ownership

What it enables: the platform team governs changes in the production traffic path, and service teams keep control of their API lifecycle.

A service workflow opens a platform PR with the exact reviewed production Gateway candidate and its provenance.
Platform automation deploys the aggregate.
Then it triggers the production Catalog workflow of the service from that source commit.

Where to look:

- [Service promotion](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/promote-prod.yaml): copying the candidate and recording its source.
- [Platform production workflow](https://github.com/KongAirlines/platform/blob/main/.github/workflows/apply-production-gateway.yaml): governed Gateway delivery and Catalog dispatch.
- [Service production Catalog workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/apply-prod-catalog.yaml): deployment with the service identity.

Adapt: your review policies, your production topology, and your approval process.
An organization can use this pattern without a separate platform repository.

Keep: the reviewed artifact and its source identity across the handoff.
Do not regenerate a different candidate after approval.
A service can deploy Catalog resources without production Gateway write access.

## Keep environments on one default branch

What it enables: development and production change independently, and you don't maintain environment branches.

The example uses separate resources, files, and credentials for each stage.
Development Gateway writes are scoped to the tagged configuration of one service.
The platform reviews production Gateway state and synchronizes it as one aggregate.

Where to look:

- [Development manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/dev.yaml) and [production manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/prod.yaml): explicit stage resources.
- [Gateway generator](https://github.com/KongAirlines/bookings/blob/main/scripts/generate-gateway.sh): environment and ownership tags.
- [Production aggregate](https://github.com/KongAirlines/platform/blob/main/konnect/production-gateway.yaml): the synchronization boundary that the platform owns.

Adapt: the number of stages, control planes, and repositories.

Keep: explicit reconciliation scopes.
Stages that synchronize independently must not prune the resources of each other.
Namespaces and decK tags scope desired state.
They don't replace RBAC.

## Prepare releases without editing automation

What it enables: a team chooses a release through a reviewed PR and doesn't change version numbers inside deployment scripts.

The release workflow retains a stable contract, selects it for production, and advances the root development contract.
Generation reads that selection.
Older contracts stay available and the workflow doesn't overwrite them.

Where to look:

- [Release workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/release-api.yaml): release inputs and PR creation.
- [Release preparation](https://github.com/KongAirlines/bookings/blob/main/scripts/prepare-release.sh): file transformations and production selection.
- [Release validation](https://github.com/KongAirlines/bookings/blob/main/scripts/validate-api-releases.sh): tests for retained releases and version changes.

Adapt: your version conventions, your compatibility tests, and your retention policy.
The beta naming convention is an example choice and federation doesn't require it.

Keep: the connection between the retained contract, the production selector, and the generated candidate.
Review the release and its deployment consequences together.

## Connect delivery to developer onboarding

What it enables: API publication includes documentation, discovery, and an application access process, in addition to Gateway routing.

The platform owns Dev Portal content and application authentication strategies.
Services publish their APIs to those Dev Portals.
Flights and Destinations show public access.
Bookings and Customer show access with an approved application key.

Where to look:

- [Shared Portal content](https://github.com/KongAirlines/platform/tree/main/konnect/portal): pages, navigation, and reusable guide snippets.
- [Platform foundations](https://github.com/KongAirlines/platform/blob/main/konnect/foundations.yaml): Dev Portals and application authentication strategies.
- [Bookings publication](https://github.com/KongAirlines/bookings/blob/main/konnect/prod.yaml): service-owned publication that uses a shared strategy.

Adapt: your audience, your Dev Portal visibility, your approval process, and your authentication strategy.
Before you copy the protected API policies, read the [authentication decisions](/konnect-reference-platform/faq/#how-do-public-and-protected-apis-coexist).

Keep: the difference between documentation visibility and runtime authorization.
An application identity is different from a passenger identity.
The example service source uses fictional accounts, so it doesn't show how a deployed upstream behaves.

## Start with one pattern

Choose a small outcome, such as showing generated Gateway differences in PRs.
Inspect its inputs, its workflow, its generated files, and its trust boundaries.
Implement that practice in one repository and test its behavior before you extend it.
That practice doesn't need the complete KongAirlines topology or authentication design.

If you use a coding agent, give it the outcome that you selected, the linked example files, and the constraints of your repository.
Ask it to explain the dependencies and the tests before it proposes changes.
The optional
[Reference Platform skill](https://github.com/Kong/ai-marketplace/tree/main/plugins/kong-konnect/skills/konnect-reference-platform)
gives the agent more guidance.
Your own manifests and policies remain the source of truth.
