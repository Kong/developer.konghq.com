---
title: Design decisions and FAQ
content_type: reference
layout: reference
products:
  - konnect-reference-platform
works_on:
  - konnect
description: Answers about the KongAirlines example, including ownership boundaries, reconciliation policies, credentials, and authentication choices.
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
faqs:
  - q: "Must I adopt the whole example?"
    a: |
      No. You don't need to adopt the whole KongAirlines example.
      KongAirlines shows one approach and doesn't define a required architecture.
      Choose a [pattern](/konnect-reference-platform/patterns/) that addresses your needs and adapt it to your existing engineering platform.
      You don't need deployment credentials to read the public implementation.
  - q: "What is the source of truth?"
    a: |
      In the KongAirlines example, the source of truth is the desired state in the owning repository.
      It includes the OpenAPI contracts, the transformation inputs, the [kongctl](/kongctl/) manifests, and the committed generated decK configuration.
      The platform repository keeps the reviewed production Gateway copy.
      Live {{site.konnect_short_name}} state helps you test a deployment.
      It doesn't replace the reviewed desired state.
  - q: "Why do service repositories manage Konnect directly?"
    a: |
      Service teams understand their APIs and keep ownership of the API lifecycle.
      They manage [Catalog](/catalog/) APIs, versions, specifications, and publications directly, including in production.
      The platform team owns shared infrastructure and production Gateway changes.
      A promotion PR governs the production traffic path and leaves Catalog ownership with the service team.
  - q: "Are namespaces and tags security boundaries?"
    a: |
      No. Namespaces and tags aren't security boundaries in {{site.konnect_short_name}}.
      {{site.konnect_short_name}} RBAC determines what an identity is authorized to change.
      The kongctl namespaces and the decK select tags limit which desired-state resources a synchronization manages.
      Use authorization and reconciliation scoping together.

      The example uses separate development and production Catalog namespaces because the stages synchronize independently.
      Development Gateway state uses tags that belong to each service.
      The platform synchronizes production as one reviewed aggregate.
  - q: "Does the example enforce least privilege everywhere?"
    a: |
      No. The example gives service identities write access to the development Gateway and read access to the production control plane.
      Service identities have no write access to the production Gateway.
      The example uses broad Catalog API roles to keep the first setup simple.
      Those roles don't isolate the Catalog APIs of one service team from another.
      Review and refine the permissions for your own resource boundaries.
  - q: "Why keep both environments on the default branch?"
    a: |
      Separate files and named resources make the differences between stages explicit, and the example doesn't use branches as environments.
      The example also uses separate Catalog API entities, Dev Portals, and application authentication strategies for development and production.
      This is the implemented topology and no organization must copy it.
      Review it again as your needs and the supported {{site.konnect_short_name}} capabilities change.
  - q: "Why retain versions instead of updating specifications in place?"
    a: |
      The example treats released contracts as immutable and development versions as append-only.
      Reviewers can identify the contract that the team selected for production and inspect its generated configuration.

      Development adds the new child version through a separate apply manifest and omits the versions collection from the sync manifest.
      Production explicitly retains released versions in its manifest.
      This design stops the synchronization from treating retained development history as stale state and deleting it.
      Retention is a policy of the example, and other version lifecycles are possible.
  - q: "How are Access Control Enforcement operation removals authorized?"
    a: |
      With kongctl 1.21 or later, a managed API can declare `force_delete: true`.
      This field authorizes updates that remove operations mapped to [Access Control Enforcement (ACE)](/plugins/ace/) from the current specification of the API.
      The example enables the field on development and production APIs.
      This includes public APIs that link to control planes with ACE enabled.

      The field doesn't request deletion of the API and doesn't bypass other validation.
      The authorization lasts as long as the field stays enabled.
      Set the field on the managed parent API.
      Do not set it on versions, external APIs, or file defaults.
      The field is an execution policy, and a dump of live {{site.konnect_short_name}} state doesn't infer it.

      Declarative reconciliation selects the target version without a custom transition script.
      This authorization doesn't change the version retention policy of the example.
  - q: "How are credentials and approvals separated?"
    a: |
      Each service repository uses its own {{site.konnect_short_name}} system account.
      The platform desired state assigns existing accounts to teams.
      Operators issue the tokens and put them in GitHub Environment secrets as part of the setup.
      A separate GitHub App credential opens the cross-repository promotion PRs and dispatches the service workflows.

      Production Gateway jobs and production Catalog jobs have separate environment approvals because they have different owners and identities.
      The example keeps validation without credentials separate from automation that can write.
      Do not expose deployment or write credentials to untrusted PR code.
  - q: "How do public and protected APIs coexist?"
    a: |
      The platform owns the Key Auth strategies of Dev Portal for each stage.
      It also owns the global ACE plugin with an anonymous fallback.
      Operations in Flights and Destinations that are public can proceed without application credentials.
      Publications in Bookings and Customer select a Key Auth strategy.

      Each protected Gateway Service also has an access guard that the service owns.
      The guard runs after ACE and rejects anonymous access.
      If a Service has both public and protected operations, scope the guard to the protected Routes.
      OpenAPI security declarations don't configure these runtime policies.

      Developers register applications, request API access, get approval, and generate keys in [Dev Portal](/dev-portal/).
      Public documentation visibility doesn't give access to protected operations.
  - q: "Is the API key a passenger identity?"
    a: |
      No. The API key in the KongAirlines example identifies the registered application.
      It doesn't identify a passenger or the developer who is signed in to Dev Portal.

      The guard for protected Services uses `kong.ctx.shared.ace.application_id` from Gateway 3.16.
      It overwrites the `X-KongAir-Account-ID` header that goes to the upstream.
      It removes the legacy passenger header and the API key before it proxies the request.
      The service source shows fictional accounts that belong to that application ID.
      Key rotation doesn't select another application.

      Read the [guard input](https://github.com/KongAirlines/bookings/blob/main/gateway/application-auth.yaml) before you adapt it.
      When you upgrade Gateway, make sure that the ACE context integration still works.
      A service that relies on an internal identity header needs a trusted boundary between the Gateway and the service.
      The delivery workflows don't deploy or change the existing upstream service at api.kong-air.com.
      To test hosted end-to-end behavior, send requests through a running Gateway to that upstream service.
  - q: "Why link Catalog APIs to a control plane?"
    a: |
      A control plane implementation lets ACE use the operations in the specification for access decisions.
      These decisions are independent of Gateway routing.
      A service-level implementation uses the relationships between Gateway Services and Routes as the access boundary.
      Choose the relationship that matches your authorization model.
  - q: "What happens when synchronization fails?"
    a: |
      When a synchronization fails, read the failed workflow and its plan before you retry.
      A completed Gateway deployment and a pending or failed Catalog deployment are separate results.
      The system doesn't roll them back as one transaction.
      Keep the source commit and the reviewed artifact aligned during recovery.
      RBAC propagation can also delay access after a role change.

      A successful run that makes no changes doesn't test an operation-removing version transition or runtime authentication.
  - q: "Can a coding agent help me adapt the patterns?"
    a: |
      Yes. A coding agent can help you adapt the KongAirlines patterns.
      The optional
      [Reference Platform skill](https://github.com/Kong/ai-marketplace/tree/main/plugins/kong-konnect/skills/konnect-reference-platform)
      gives guidance to agents.
      Give the agent the outcome that you want, the relevant example files, and the constraints of your own repository.
      Ask it to identify the ownership and security boundaries before it changes anything.
      The skill is optional and isn't a separate source of configuration.
---

The KongAirlines example makes specific choices about ownership, reconciliation, credentials, and authentication.
The following answers explain those choices and the alternatives for your own platform.
