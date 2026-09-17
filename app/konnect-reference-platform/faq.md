---
title: Frequently asked questions
content_type: reference
layout: reference
products:
  - konnect-reference-platform
works_on:
  - konnect
description: Answers about ownership, environments, authorization, and delivery.
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: KongAirlines implementation
    url: /konnect-reference-platform/kong-air/
  - text: APIOps workflows
    url: /konnect-reference-platform/apiops/
  - text: Adopt the architecture
    url: /konnect-reference-platform/how-to/
---

## Is the Reference Platform a tool I install?

No. It is a maintained reference architecture plus the public
[KongAirlines](https://github.com/KongAirlines) implementation. Copy and adapt
the manifests and workflows that fit your organization. There is no Reference
Platform CLI, operator, installer, or generated registry.

## What is the source of truth?

The owning repository's OpenAPI documents, kongctl manifests, and decK files.
The decK files are generated deterministically from OpenAPI plus explicit
plugin inputs and committed for review. No additional declarative format sits
above kongctl and decK.

## Why do service repositories manage Konnect directly?

Federation keeps API lifecycle state with the Service Team that understands it.
Each repository uses its own automation identity and resolves shared resources
managed by the Platform Team. This avoids a central process polling service
repositories or copying their specifications.

## What does the Platform Team own?

Organization teams and access, Developer Portals, application auth strategies,
control-plane provisioning and lifecycle, and the aggregate production Gateway
configuration. Service Teams own Catalog APIs, versions, specs,
implementations, publications, and development Gateway state.

## Are kongctl namespaces an RBAC boundary?

No. A namespace records which declarative owner participates in planning and
helps constrain reconciliation. Konnect roles determine whether an identity is
authorized to read or mutate a resource. Use both.

## How are development and production represented?

Use one default branch with distinct files and resources. Under the current
Catalog model, each service declares separate development and production API
entities because one API can link to only one control plane. Development APIs
publish privately to the development Portal; production APIs publish publicly
to the production Portal.

Do not base a current architecture on unreleased environment-aware Catalog or
Workspace behavior. Re-evaluate the duplication after those capabilities are
generally available and supported declaratively.

## How does an OpenAPI document become a production release?

The root `openapi.yaml` represents the next beta. A manually dispatched release
workflow opens a service PR that creates an immutable stable file under
`openapi/versions/`, selects it as the production API's current version in
`konnect/prod.yaml`, advances the root to the next beta, and regenerates Gateway
state. Generation reads the production selector, so releasing never requires a
script edit.

## Who owns development Gateway configuration?

The Platform Team provisions one development control plane per service team and
grants that team's repository identities access. Each service repository owns
its Gateway Service, Routes, and service-scoped plugins. Unique names and tags
let sibling repositories share a control plane without a central development
configuration repository.

## Who owns production Gateway configuration?

The Platform Team. A Service Team generates the candidate, but a promotion PR
moves an exact copy into the platform repository for governance. Only the
platform automation identity writes production Gateway state. Catalog state
remains service-owned and is applied after the Gateway change.

## Why are Bookings and Customer Information protected differently?

Their publications select a Key Auth application auth strategy and their
Gateway Services run Access Control Enforcement (ACE) with
`match_policy: required`. Their Catalog APIs link to a control plane, enabling
ACE to enforce application access at the OpenAPI operation level. Destinations
and Flights are anonymous examples and use neither an auth strategy nor ACE.

## Why not link protected APIs directly to a Gateway Service?

A service implementation makes Gateway routing relationships define the access
boundary. A control-plane implementation lets ACE use the API specification's
operations for access decisions while routing remains independently managed in
decK. This also supports API composition and packaging scenarios.

## What happens when a resource is removed from a manifest?

Nothing automatically in v1. All workflows use `kongctl apply`, so omission is
not a deletion request. Use an explicit, reviewed additive correction. Sync,
pruning, and deletion procedures are deferred until ownership-safe behavior is
designed and demonstrated.

## How are credentials bootstrapped?

Create one Konnect system account and token per service repository, assign its
team membership through the platform desired state, and store the token in a
protected GitHub secret. The service team owns the shared roles inherited by
its repository accounts. Token creation and secret placement are human
bootstrap steps. Production promotion uses a separate GitHub credential that
can open a PR in the platform repository and is never exposed to fork jobs.

## What if an apply fails immediately after an RBAC change?

Konnect role propagation can be eventually consistent. For the initial model,
rerun the failed apply after propagation completes. Do not compensate by adding
a second orchestration layer.

## Is an AI assistant skill available?

Yes. The optional
[`konnect-reference-platform` skill](https://github.com/Kong/ai-marketplace/tree/main/plugins/kong-konnect/skills/konnect-reference-platform)
in the Kong AI Marketplace helps agents apply and review this ownership model.
It composes the supported kongctl and decK workflows; it is not a prerequisite,
configuration source, or replacement for the public example.
