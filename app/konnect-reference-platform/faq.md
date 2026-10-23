---
title: Design decisions and FAQ
content_type: reference
layout: reference
products:
  - konnect-reference-platform
works_on:
  - konnect
description: Understand the example's ownership boundaries, reconciliation policies, and authentication choices.
breadcrumbs:
  - /konnect-reference-platform/
related_resources:
  - text: Reference Platform
    url: /konnect-reference-platform/
  - text: Explore KongAirlines
    url: /konnect-reference-platform/kong-air/
  - text: Follow an API change
    url: /konnect-reference-platform/apiops/
  - text: Adapt patterns from KongAirlines
    url: /konnect-reference-platform/patterns/
---

## Must I adopt the whole example?

No. KongAirlines demonstrates one approach, not a required architecture.
Choose a [pattern](/konnect-reference-platform/patterns/) that addresses your
needs and adapt it to your existing engineering platform. You do not need
deployment credentials to read the public implementation.

## What is the source of truth?

The owning repository's OpenAPI contracts, transformation inputs,
[kongctl](/kongctl/) manifests, and committed generated decK configuration.
The platform repository retains the reviewed production Gateway copy.
Live Konnect state helps verify deployment; it does not replace the reviewed
desired state.

## Why do service repositories manage Konnect directly?

Service teams understand their APIs and retain their lifecycle ownership.
They manage Catalog APIs, versions, specifications, and publications directly,
including in production. The platform team owns shared infrastructure and
production Gateway changes. A promotion PR governs the production traffic path
without transferring Catalog ownership.

## Are namespaces and tags security boundaries?

No. Konnect RBAC determines what an identity is authorized to change.
kongctl namespaces and decK select tags constrain which desired-state resources
a synchronization manages. Use authorization and reconciliation scoping together.

The example uses separate development and production Catalog namespaces because
the stages synchronize independently. Development Gateway state uses service-specific
tags; the platform synchronizes production as one reviewed aggregate.

## Does the example enforce least privilege everywhere?

The example gives service identities development Gateway write access and
production control-plane read access, not production Gateway write access.
It uses broad Catalog API roles for initial simplicity. Those roles are not
a demonstration of strict isolation between every service team's Catalog APIs.
Review and refine permissions for your own resource boundaries.

## Why keep both environments on the default branch?

Separate files and named resources make stage differences explicit without
using branches as environments. The example also uses separate Catalog API
entities, Portals, and application authentication strategies for development
and production. This is the implemented topology, not a requirement for every
organization. Reassess it as your needs and supported Konnect capabilities evolve.

## Why retain versions instead of updating specifications in place?

The example treats released contracts as immutable and development versions
as append-only. Reviewers can identify the contract selected for production
and inspect its generated configuration.

Development adds the new child version through a separate apply manifest and
omits the versions collection from the sync manifest. Production explicitly
retains released versions in its manifest. This avoids treating retained
development history as stale state and deleting it. Retention is a deliberate
example policy, not the only possible version lifecycle.

## How are ACE operation removals authorized?

With kongctl 1.21 or newer, a managed API can declare
`force_delete: true` to authorize updates that remove ACE-mapped operations
from its current specification. The example enables it on development and
production APIs, including public APIs linked to ACE-enabled control planes.

It does not request deletion of the API or disable runtime authorization.
The authorization persists while the field remains enabled. It belongs on the
managed parent API, not on versions, external APIs, or file defaults. It is an
execution policy and is not inferred by a dump of live Konnect state.

Declarative reconciliation now selects the target version without a custom
transition script. This authorization does not change the example's version
retention policy.

## How are credentials and approvals separated?

Each service repository uses its own Konnect system account. Platform desired
state assigns existing accounts to teams; issuing tokens and placing them in
GitHub Environment secrets are operator setup tasks. A separate GitHub App
credential opens cross-repository promotion PRs and dispatches service workflows.

Production Gateway and Catalog jobs have separate environment approvals because
they use different owners and identities. Credential-free validation is kept
separate from write-capable automation. Do not expose deployment or write
credentials to untrusted PR code.

## How do public and protected APIs coexist?

The platform owns stage-specific Dev Portal Key Auth strategies and global
[Access Control Enforcement](/plugins/ace/) with an anonymous fallback.
Public Flights and Destinations operations can proceed without application
credentials. Bookings and Customer publications select a Key Auth strategy.

Protected Gateway Services also have a service-owned access guard that runs
after ACE and rejects anonymous access. For a Service containing both public
and protected operations, scope the guard to protected Routes. OpenAPI
security declarations alone do not configure these runtime policies.

Developers register applications, request API access, obtain approval, and
generate keys through Dev Portal. Public documentation visibility does not
grant access to protected operations.

## Is the API key a passenger identity?

No. The key identifies the registered application, not a passenger or the
developer signed into the Portal.

The example's protected-Service guard uses Gateway 3.16's
`kong.ctx.shared.ace.application_id` to overwrite the upstream
`X-KongAir-Account-ID` header. It removes the legacy passenger header and API
key before proxying. The service source illustrates fictional accounts scoped
to that application ID; key rotation does not select another application.

Inspect the [guard input](https://github.com/KongAirlines/bookings/blob/main/gateway/application-auth.yaml)
before adapting it. Its ACE context integration must be verified when upgrading
Gateway, and services relying on an internal identity header need a trusted
Gateway-to-service boundary. The delivery workflows do not deploy or change
the existing upstream service at api.kong-air.com. Source tests and successful
configuration runs do not establish hosted end-to-end compatibility.

## Why link Catalog APIs to a control plane?

Control-plane implementations let ACE use specification operations for access
decisions independently of Gateway routing. Service-level implementations
instead use Gateway Service and Route relationships as the access boundary.
Choose the relationship that matches your authorization model.

## What happens when synchronization fails?

Inspect the failed workflow and its plan before retrying. A completed Gateway
deployment and a pending or failed Catalog deployment are separate outcomes,
not a single rolled-back transaction. Keep the source commit and reviewed
artifact aligned when recovering. RBAC propagation can also delay access after
a role change.

Do not treat a successful no-op run as proof that an operation-removing version
transition or runtime authentication has been tested.

## Can a coding agent help me adapt the patterns?

Yes. The optional
[Reference Platform skill](https://github.com/Kong/ai-marketplace/tree/main/plugins/kong-konnect/skills/konnect-reference-platform)
provides guidance for agents. Give the agent the outcome you want, relevant
example files, and your own repository constraints. Ask it to identify the
ownership and security boundaries before making changes. The skill is not
a prerequisite or a separate configuration source.
