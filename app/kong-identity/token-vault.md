---
title: "Token vault"
content_type: reference
layout: reference
permalink: /identity/token-vault/
products:
  - identity
  - konnect
works_on:
  - konnect

breadcrumbs:
  - /identity/

description: "Store third-party credentials with {{site.identity}} Token Vault"

api_specs:
    - konnect/kong-identity

related_resources:
  - text: "{{site.identity}} authorization servers, claims, scopes, and clients"
    url: /identity/auth-servers/
  - text: Principals and directories
    url: /identity/principals/

faqs:
  - q: "Why use he {{site.identity}} Token Vault instead of connectors in LLM services?"
    a: |
      Connectors are client-owned: each time a user needs to connect an LLM to a service, they need to set up a connector inside each service. The Token Vault makes the Gateway sit in front of any client. You can use different agents with a single credential store, with a way to revoke access locally. Using the Token Vault prevents agents from accessing authorization tokens and provides a way of federating identities around corp IdP like Okta.  
---


The {{site.identity}} Token Vault is a {{ site.konnect_short_name }} built-in credential broker. 
It stores your users' credentials for third-party upstream services (such as GitHub, Slack, 
or Workday) and releases them to {{ site.ai_gateway_name }} so agents can call those protected 
services on a user's behalf, without the agent ever holding the credential itself.

## Use cases

Set up the {{site.identity}} Token Vault in the following cases:

{% table %}
columns:
  - title: Use case
    key: case
  - title: Examples
    key: examples
rows:
  - case: "Credentials brokering"
    examples: |
      * An agent calls a third-party API on a user's behalf, without ever touching the credentials
      * Token storage for future calls after a one-time OAuth
  - case: "Choose per-user vs. shared credentials"
    examples: |
      * Per-user: each principal keeps their own GitHub identity, enrolled and refreshed independently
      * Shared: an admin enrolls one Slack bot token once, released to any authorized caller
  - case: "Store and reuse different secrets types"
    examples: |
      * Static API keys
      * Client-credentials
      * Authorization code
  - case: "Federate identity"
    examples: |
      Use the Token Vault as single broker for different trust chains:

      * Standard OAuth2 with corp IdP (like Okta)
      * Token exchange (ID-JAG)
  - case: "Enforce auth governance"
    examples: |
      * Disable a provider for enterprise kill-switch
      * Audit credential releases without logging the credential itself
{% endtable %}


## How the token vault works

The following diagram shows how the  {{site.identity}} Token Vault works on top of the following setup:
* Okta as corp IdP
* Claude Code as the agent, configured with an {{site.ai_gateway}} MCP server
* GitHub as the third-party service
* {{site.identity}} Token Vault as credentials broker
* AI Gateway as the token handler between Okta and the Token Vault

In this scenario:
1. A user authenticates to Okta, which generates a token.
1. The {{site.ai_gateway}} captures the token and hands it to Token Vault.
1. The first time the {{site.ai_gateway}} detects the user on GitHub, it requires them to connect their GitHub account before continuining.
1. The Token Vault stores the credentials it extracts from the verified Okta token.
1. Claude Code can use the `tools/list` from the GitHub MCP: the user can now interact with GitHub from Claude Code.

{% include diagrams/token-vault.md %}


The following tables show what using the Token Vault brings to your authentication setup and flows:

{% table %}
columns:
  - title: "Setup"
    key: aspect
  - title: Without Token Vault
    key: without
  - title: With Token Vault
    key: with
rows:
  - aspect: "**Where the credential lives**"
    without: |
      Wherever that specific connector/client stores it, scoped to that one product:
      * Its own database
      * Its own encrypted config
    with: |
      Centralized in the vault, scoped to the org's {{site.identity}} directory.
  - aspect: "**Who manages it**"
    without: |
      Each connector/extension vendor, independently: no shared admin control across tools.
    with: |
      One admin surface, across every agent/client behind {{site.ai_gateway_name}}.
  - aspect: "**Reuse across agents**"
    without: |
      Not reusable. Claude's Slack connector token can't be used by Cursor or a custom agent. Each re-does its own OAuth consent.
    with: |
      One enrollment, reusable by any agent that calls through {{site.ai_gateway_name}}
  - aspect: "**Revocation/audit**"
    without: |
      Depends entirely on that connector vendor's own tooling. May or may not be centrally visible.
    with: |
      Uniform audit trail and revocation regardless of which agent triggered the original consent.
{% endtable %}

Key facts:
* Only the {{site.ai_gateway_name}} can call the Token Vault, and that connection is locked down over mutual TLS (mTLS): both sides prove their identity with certificates.
* Agents and MCP clients never call the Token Vault directly: if an agent needs a credential, it has to go throught the {{site.ai_gateway_name}}.
* The Token Vault never calls the corp IdP; it uses the IdP's public keys (JWKS) to verify that:
  * The token's signature is valid.
  * The token was issued by an IdP the {{site.ai_gateway_name}}  set as trusted for that directory.

## Token vault components

<!--
Lead with a table summarizing component / scope / purpose, then a subsection each.
-->

### Directory

<!-- Existing {{site.identity}} directory; gains a vault_enabled flag. Link to /identity/principals/. -->

### Trusted IdP

<!--
Per directory. The issuer URL (and optional JWKS URI) whose tokens the vault will trust when
verifying a caller's subject token. Independent of any {{site.identity}} authorization server,
though an {{site.identity}} authorization server can itself be the trusted IdP.
Validated IdPs: {{site.identity}}, Okta, Entra, AWS Cognito, PingFederate, Keycloak, Auth0.
-->

<!-- TODO: confirm the IdP list is a supported matrix and not just a validation target. -->

### Provider template

<!--
Global, owned by Kong, not managed through the public API. Defines the upstream's OAuth
endpoints, secret type, available scopes, credential placement, and default base URL.
Explain why it matters to the reader: a provider's scopes must be a subset of the template's
available scopes, and credential injection settings come from the template.
-->

### Provider

<!--
Per directory. A tenant binding of a template: client ID, client secret, scopes, credential type.
Cover credential_type here:
* user (default) — each user enrolls their own account; credential keyed per subject.
* shared — an admin enrolls once; the credential is released to any authorized gateway caller.
Catalog at launch: GitHub, Atlassian, Atlassian Rovo, Snowflake, Google, Slack, Figma, Databricks,
plus custom providers defined by supplying OAuth endpoints directly. Atlassian Rovo supports DCR.
-->

<!-- TODO: confirm the provider catalog is a supported list and not just a validation target. -->

### Credentials

<!--
The stored upstream token, keyed by (provider, issuer, subject). Encrypted at rest.
Never returned in an API response. Point forward to the security section.
-->

### The {{site.ai_gateway}} role

<!--
Two plugins cooperate on the route fronting the upstream MCP server:
* AI MCP OAuth2 — publishes RFC 9728 protected-resource metadata, issues the 401 challenge,
  verifies the caller's token against the corp IdP. Must be configured to pass the caller's
  bearer token through unmodified, or the vault never receives a subject token.
* AI MCP Proxy — performs the token exchange against the vault and injects the returned
  credential into the upstream call.
Link to /plugins/ai-mcp-oauth2/ and /plugins/ai-mcp-proxy/.
-->

<!-- TODO: token_vault config does not exist in the AI MCP Proxy schema yet. Confirm the
     field names and whether a provider is targeted by name or UUID before documenting. -->

## Credential enrollment

<!--
The most visible behavior on this feature — give it its own section.
Sequence: first tool call for an unconnected provider -> vault returns 401 with an enrollment
URL -> gateway surfaces it to the client via MCP elicitation -> user completes the provider's
consent flow -> vault stores the credential -> user retries and the call succeeds.
Then: the vault refreshes stored credentials in the background, so users are only re-prompted
when the provider genuinely requires it.
Note the enrollment link is short-lived (10 minutes).
-->

## ID-JAG and Enterprise Managed Authorization

<!--
Define the terms once, before the table:
* EMA (Enterprise Managed Authorization) — MCP extension where the corporate IdP both
  authenticates and authorizes an agent's access to an MCP resource.
* ID-JAG (Identity Assertion JWT Authorization Grant) — the short-lived assertion it mints.
* XAA (Cross-App Access) — Okta's implementation of EMA.

Then a table keyed on three axes, because which approach applies depends on all three:
corporate IdP | MCP client | upstream authorization server | approach
-->

### {{site.identity}} authorization server as an ID-JAG consumer

<!--
When the corp IdP and MCP client speak ID-JAG but the upstream MCP server does not.
Client logs in to its IdP, exchanges the id_token for an ID-JAG scoped to
{{site.identity}} (RFC 8693), redeems it at {{site.identity}} (RFC 7523) for an access token,
and calls the gateway with that. The directory's trusted IdP is the {{site.identity}}
authorization server itself; from there the flow continues as described above.
-->

### Token vault as an ID-JAG provider

<!--
When the corp IdP does not issue ID-JAGs but the upstream's authorization server accepts them.
Applies to the vault-to-upstream leg only — the caller-to-vault leg is unchanged.
An admin selects an {{site.identity}} authorization server as the issuing identity, so its
issuer URL becomes the ID-JAG's iss and the upstream fetches its JWKS to verify the signature.
Stress: the vault mints and signs the assertion itself; it does not request one from that
authorization server's token endpoint. It redeems using the provider's own client ID, because
RFC 7523 requires the assertion's client ID to match the client authenticating the redemption.
-->

### Full ID-JAG chain with the ID-JAG Relay plugin

<!--
When the corp IdP, the MCP client, and the upstream MCP server all support ID-JAG.
The plugin runs the RFC 8693 exchange and the RFC 7523 redemption on the route directly,
bypassing the token vault entirely. Include the standards-gap warning below.
-->

<!-- TODO: plugin name is inconsistent in the source (id-jag-relay vs id-jag-impersonate) and
     no plugin page exists yet. Confirm the shipping name and link it. -->

## Limitations

<!--
Scope each limitation to what it actually affects.

The ID-JAG relay path is standards-compliant end to end, but running it through a proxy hits
two gaps in the specs it depends on:
* RFC 9728 requires the protected resource metadata's resource value to match the identifier
  the client used verbatim, which a proxy fronting a real upstream cannot satisfy.
* There is no sanctioned way for a trusted intermediary to negotiate an ID-JAG on a client's
  behalf.
Frame as a current standards gap. Do not publish the proposed IETF exemption or link the
working group issue.

Also list:
* The vault is not a policy enforcement point.
* Customer-managed encryption keys (BYOK) are not available.
* Konnect only.
-->

## Security and compliance

### Credential storage

<!--
Envelope encryption: a per-directory vault key wraps a per-row data key; row identity is bound
into the ciphertext so a credential cannot be moved between rows. Secret values are never
returned in API responses. Root keys are Kong-managed; customer-managed keys are not available.
-->

### Auditing

<!--
Every credential lookup emits a structured record covering successful outcomes — credential
released, or enrollment required — with the directory, provider, secret type, credential type,
calling gateway, subject, and decision. Secret values, released tokens, client secrets, refresh
tokens, and OAuth codes never appear in a record. The record is written before the credential
is released.
-->

<!-- Consider surfacing the storage and auditing questions as a faqs: block in the frontmatter,
     the way /identity/principals/ handles data residency. -->

## Enable the token vault

<!--
Keep the configuration on this page — per the site's "every page is page one" tenet, and
matching /identity/principals/, which carries its own "Create a directory" and "Configure a
principal" sections.
Use konnect_api_request blocks for each step.
-->

### Enable the vault on a directory

<!-- PATCH the directory with vault_enabled: true. Note the field also appears on GET. -->

### Configure a trusted IdP

<!--
POST the issuer URL, optionally a JWKS URI. If the JWKS URI is omitted, the vault discovers it
from the issuer's /.well-known/openid-configuration.
-->

### Register a provider

<!--
POST a provider built from a template: client ID, client secret, scopes, credential type.
Supporting content:
* A table  of required fields by secret type (API key; client credentials; authorization code).
* The scope subset rule and the error returned when it is violated.
* The callback URL the admin must register in the provider's own console — a required setup
  step, so show the URL explicitly.
-->

<!-- TODO: source shows both /vault/providers and /vault-/providers, and both template_name
     and template_id in the body. Confirm against the shipped spec. -->

### Enable credential injection on a route

<!-- Configure AI MCP Proxy to exchange the caller's token for the stored credential and inject it. -->

## Manage connected credentials

<!--
* End users: a self-service page listing every upstream account they have connected, with the
  ability to disconnect one, after which tools using that provider prompt them to authorize again.
* Admins: see which users have enrolled a credential for a provider, and revoke an individual
  user's credential so an offboarded user immediately losestable upstream access.
* Deleting a provider cascades to its credentials; purging the vault removes providers,
  secrets, and credentials.
-->

<!-- TODO: the self-service UI is "details TBD" in the source and the AI GW UI section is
     explicitly marked "not canon". Do not write UI steps until both are confirmed. -->

## Flow

1. Generate a secret (like a PAT from a third-party service).
1. Store it in the vault.
1. Retrieve the provider's ID.
1. Add it to your gateway configuration and decK apply it.