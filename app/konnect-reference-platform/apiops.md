---
title: Follow an API change through KongAirlines
content_type: reference
layout: reference
products:
  - konnect-reference-platform
works_on:
  - konnect
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

A Bookings API change moves through several repositories in the KongAirlines example, from a pull request to production.
This page explains the delivery flow that the example implements.
It's a reading guide and not a deployment checklist.
[kongctl](/kongctl/) manages {{site.konnect_short_name}} resources.
[decK](/deck/) manages Gateway configuration.
GitHub Actions connects the reviewed artifacts to delivery.

If you want a practice for your own system, see [Adapt patterns from KongAirlines](/konnect-reference-platform/patterns/).

## Start with the API contract

A service developer changes the root
[OpenAPI document](https://github.com/KongAirlines/bookings/blob/main/openapi.yaml)
on a feature branch.
The example treats this document as the next development contract.
When the contract changes, the example advances its beta version.

The [Gateway generator](https://github.com/KongAirlines/bookings/blob/main/scripts/generate-gateway.sh)
combines the contract with explicit transformation inputs.
It generates development configuration from the root contract.
It generates production configuration from the retained release that the production [Catalog](/catalog/) manifest selects.
A design change for development only doesn't change the production candidate.

Observe: the service PR contains the API design and the Gateway configuration that results from it.
It doesn't contain a script that generates unknown output later.

## Validate and materialize the PR

The [validation workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/validate-konnect.yaml)
generates both Gateway artifacts without Konnect credentials.
It makes sure that the output is correct and uploads the artifacts.

A separate [materialization workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/materialize-gateway.yaml)
makes sure that the source PR and the artifact boundaries are correct.
Then it commits the generated files to the branch in the same repository.
Validation runs again.
If the output matches, the workflow makes no further commit.

The workflow updates a PR comment that lists the changed input files and the generated Gateway differences.
The comment is an offline comparison and not a live Konnect plan.
A change to Catalog only can correctly show no generated Gateway differences.

Observe: reviewers can inspect intent and output together.
Teams express additional Gateway behavior through transformation inputs and don't edit generated files.
The credentialed workflow doesn't run scripts that the PR controls.
Fork validation doesn't receive deployment or write credentials.

## Merge to development

After the merge, the [development synchronization workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/apply-dev.yaml)
makes sure that the committed Gateway artifacts still match the generated output.
It adds the development Catalog version.
Then it synchronizes the service's Catalog state and tagged Gateway configuration with its Konnect identity.

The [development manifest](https://github.com/KongAirlines/bookings/blob/main/konnect/dev.yaml)
references the Dev Portal and the team control plane that the platform owns.
The service doesn't provision duplicate shared resources.

Observe: the service updates its development API and its Gateway configuration directly.
It doesn't deploy a production Gateway change.

## Prepare a production release

When the service is ready to release, its
[release workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/release-api.yaml)
opens another service PR.
The team supplies a stable release version and the next development version.
The team doesn't edit a deployment script.

The [release preparation script](https://github.com/KongAirlines/bookings/blob/main/scripts/prepare-release.sh) does four things:

1. It retains the stable contract as a versioned specification.
2. It selects that release in the production Catalog manifest.
3. It advances the root contract to the next development beta.
4. It generates the Gateway artifacts for review.

Validation protects retained releases from modification and deletion.
When the team merges this PR, the next beta goes to development.
The merge also proposes the reviewed production candidate through the promotion workflow.

Observe: reviewers see the selected production specification and the generated Gateway candidate together.
A team releases a contract by choice.
A development merge doesn't release a contract automatically.

## Promote through platform review

The [promotion workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/promote-prod.yaml)
copies the committed production candidate into a platform PR.
It records the source repository, the commit, the checksum, and the tool versions.
It doesn't regenerate the candidate and it doesn't deploy it to production.

The platform team reviews the candidate together with the aggregate production configuration.
After the merge and the production environment approval, the
[platform delivery workflow](https://github.com/KongAirlines/platform/blob/main/.github/workflows/apply-production-gateway.yaml)
synchronizes the reviewed Gateway state.

Observe: production Gateway changes require platform review.
Service teams keep ownership of their APIs and don't receive production Gateway write permissions.
If the Gateway configuration is the same, a promotion can still record a new reviewed source commit in the provenance.

## Publish the production Catalog state

After Gateway synchronization succeeds, platform automation reads the changed provenance.
Then it dispatches the
[production Catalog workflow](https://github.com/KongAirlines/bookings/blob/main/.github/workflows/apply-prod-catalog.yaml)
of the service that owns the change.

That workflow checks out the exact promoted commit.
After its own production approval, the service identity synchronizes the production API, the retained specifications, the implementation link, and the [Dev Portal](/dev-portal/) publication.

Observe: the platform governs the production traffic path, and the service writes its own production Catalog resources.
The two approvals protect different ownership boundaries.
These operations don't form one atomic transaction.
Failures appear in the workflow that owns the failed step.

## Connect publication to API consumption

Dev Portal shows the published contract and the application registration process.
Flights and Destinations show public operations.
Bookings and Customer show access with an application key after registration approval.

Documentation visibility, application registration, and runtime access are three different controls.
Before you adapt the protected API example, read the
[authentication decisions](/konnect-reference-platform/faq/#how-do-public-and-protected-apis-coexist).

The workflows in this page deploy Konnect and Gateway configuration.
They don't deploy the upstream application services.
To test end-to-end behavior, send requests through a running Gateway to compatible upstream services.

## Take a practice into your own platform

You can adopt reviewable generation, release PRs, or governed promotion independently.
The [pattern guide](/konnect-reference-platform/patterns/)
links each practice to its implementation and to the boundaries that you must keep.
