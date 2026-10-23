---
title: Follow an API change through KongAirlines
content_type: reference
layout: reference
products:
  - konnect-reference-platform
description: Follow an API contract through PR validation, development delivery, release preparation, and governed production promotion.
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: Explore KongAirlines
    url: /konnect-reference-platform/kong-air/
  - text: Adapt patterns from KongAirlines
    url: /konnect-reference-platform/patterns/
  - text: Frequently asked questions
    url: /konnect-reference-platform/faq/
---

Follow a Bookings API change through the example's repositories. This is a
reading guide to the implemented delivery flow, not a deployment checklist.
[kongctl](/kongctl/) manages Konnect resources, [decK](/deck/) manages Gateway
configuration, and GitHub Actions connects the reviewed artifacts to delivery.

If you are looking for a practice to bring into your own system, use
[Adapt patterns from KongAirlines](/konnect-reference-platform/patterns/).

## Start with the API contract

A service developer changes the root
[OpenAPI document](https://github.com/KongAirlines/bookings/blob/main/openapi.yaml)
on a feature branch. The example treats this as the next development contract
and advances its beta version when the contract changes.

The [Gateway generator](https://github.com/KongAirlines/bookings/blob/main/scripts/generate-gateway.sh)
combines the contract with explicit transformation inputs. It generates
development configuration from the root contract and production configuration
from the retained release selected by the production Catalog manifest.
A development-only design change need not change the production candidate.

**Observe:** the service PR contains the API design and its resulting
Gateway configuration, not only a script that will generate unknown output later.

## Validate and materialize the PR

The [validation workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/validate-konnect.yaml)
generates both Gateway artifacts without Konnect credentials. It validates the
output and uploads the artifacts.

A separate [materialization workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/materialize-gateway.yaml)
verifies the source PR and artifact boundaries, then commits generated files to
the same-repository branch. Validation runs again; matching output requires no
further commit.

The workflow updates a PR comment with changed input files and generated Gateway
differences. That comment is an offline comparison, not a live Konnect plan.
A Catalog-only change can correctly show no generated Gateway differences.

**Observe:** reviewers can inspect intent and output together. Additional
Gateway behavior is expressed through transformation inputs, not hand edits to
generated files. The credentialed workflow does not execute PR-controlled
scripts, and fork validation does not receive deployment or write credentials.

## Merge to development

After merge, [development synchronization](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/apply-dev.yaml)
checks that the committed Gateway artifacts still match generation. It adds the
development Catalog version and synchronizes the service's Catalog state and
tagged Gateway configuration with its Konnect identity.

The [development manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/dev.yaml)
references the platform-owned Portal and team control plane. The service does
not provision competing shared resources.

**Observe:** the service updates its development API and its Gateway
configuration directly. It has not deployed a production Gateway change.

## Prepare a production release

When the service is ready to release, its
[release workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/release-api.yaml)
opens another service PR. The team supplies a stable release version and the
next development version; it does not edit a deployment script.

[Release preparation](https://github.com/KongAirlines/bookings/blob/main/scripts/prepare-release.sh):

1. Retains the stable contract as a versioned specification.
2. Selects that release in the production Catalog manifest.
3. Advances the root contract to the next development beta.
4. Generates the Gateway artifacts for review.

Validation protects retained releases against modification and deletion. Merging
this PR sends the next beta to development and proposes the reviewed production
candidate through the promotion workflow.

**Observe:** the selected production specification and generated Gateway
candidate are reviewed together. Releasing a contract is an explicit choice,
not an automatic consequence of every development merge.

## Promote through platform review

The [promotion workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/promote-prod.yaml)
copies the committed production candidate into a platform PR. It records the
source repository, commit, checksum, and tool versions. It does not regenerate
the candidate or deploy it to production.

The platform team reviews the candidate alongside the aggregate production
configuration. After merge and production-environment approval, the
[platform delivery workflow](https://github.com/KongAirlines/platform/blob/main/.github/workflows/apply-production-gateway.yaml)
synchronizes the reviewed Gateway state.

**Observe:** production Gateway changes cross a review boundary. Service teams
retain API ownership without receiving production Gateway write permissions.
A provenance-only promotion can identify a new reviewed source commit even
when the Gateway configuration is unchanged.

## Publish the production Catalog state

After successful Gateway synchronization, platform automation reads changed
provenance and dispatches the owning service's
[production Catalog workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/apply-prod-catalog.yaml).

That workflow checks out the exact promoted commit. After its own production
approval, the service identity synchronizes the production API, retained
specifications, implementation link, and Portal publication.

**Observe:** the platform governs the production traffic path, while the
service still writes its own production Catalog resources. The two approvals
protect different ownership boundaries. These operations are not one atomic
transaction; failures are visible in the owning workflow.

## Connect publication to API consumption

The Portal presents the published contract and the application registration
process. Flights and Destinations illustrate public operations. Bookings and
Customer illustrate protected application-key access after registration approval.

Documentation visibility, application registration, and runtime access are
different controls. Read the
[authentication decisions](/konnect-reference-platform/faq/#how-do-public-and-protected-apis-coexist)
before adapting the protected-API example.

The workflow sequence above deploys Konnect and Gateway configuration, not the
upstream application services. A successful configuration run does not by itself
prove end-to-end runtime behavior; that requires requests through a running
Gateway and compatible upstream services.

## Take a practice into your own platform

You can adopt reviewable generation, release PRs, or governed promotion
independently. The [pattern guide](/konnect-reference-platform/patterns/)
links each practice to its implementation and the boundaries worth preserving.
