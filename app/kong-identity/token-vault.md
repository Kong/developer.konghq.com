---
title: "Token Vault"
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
    - konnect/kong-identity-principals

related_resources:
  - text: Get started with the {{site.identity}} Token Vault
    url: /how-to/get-started-with-token-vault/
  - text: "{{site.identity}} Token Vault credentials"
    url: /identity/token-vault/credentials/
  - text: Principals
    url: /identity/principals/
  - text: Directories
    url: /identity/directories/

faqs:
  - q: "Why should I use the {{site.identity}} Token Vault instead of connectors in LLM services?"
    a: |
      Connectors are client-owned: each time a user needs to connect an LLM to a service, they need to set up a connector inside each service. Token Vault makes the Gateway sit in front of any client. You can use different agents with a single credential store, with a way to revoke access locally. Using Token Vault prevents agents from accessing authorization tokens and provides a way of federating identities around corp IdP like Okta.  
---


The {{site.identity}} Token Vault is a {{ site.konnect_short_name }} built-in credential broker. 
It stores your users' credentials for third-party upstream services (for example, GitHub, Slack, 
or Workday) and releases them to {{ site.ai_gateway_name }} so agents can call those protected 
services on a user's behalf, without the agent ever holding the credential itself.

## Use cases

Set up the {{site.identity}} Token Vault in the following cases:

<!--vale off-->
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
  - case: "Store and reuse different secret types"
    examples: |
      * Static API keys or tokens (`static_secret`)
      * Authorization code, with optional PKCE and dynamic client registration (DCR)
  - case: "Federate identity"
    examples: |
      Use Token Vault as a single broker for users authenticated with a corp IdP (like Okta), without provisioning them in {{site.identity}} first.
  - case: "Enforce auth governance"
    examples: |
      * Disable a provider as an enterprise kill switch
      * Audit credential releases without logging the credential itself
{% endtable %}
<!--vale on-->


## How Token Vault works

The following diagram shows how a request flows from a principal to a third-party credential provider through the {{site.identity}} Token Vault:

1. A principal (your users, agents, and applications) sends a request through {{site.ai_gateway}}.
1. {{site.ai_gateway}} routes the request to an MCP server or a Model Provider with a Token Vault provider attached for outbound authentication.
1. Token Vault verifies the caller's token with the trusted IdP, using the token's issuer (`iss`) and subject (`sub`) to identify the principal.
1. Token Vault releases the matching credential for the credential provider, such as GitHub or Slack. If the principal doesn't have a credential for that provider yet, {{site.ai_gateway}} returns an enrollment URL so they can connect their account first. The URL is a link for the MCP servers that support the [URL elicitation mode](https://modelcontextprotocol.io/specification/2025-11-25/client/elicitation) and text for other clients. See [Credential enrollment](/identity/token-vault/credentials/#credential-enrollment).

The IdP token only identifies the principal. It never becomes the stored credential.

{% include diagrams/token-vault.md %}


The following table shows what using Token Vault brings to your authentication setup and flows:

<!--vale off-->
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
      Stored separately by each connector or client, for example in its own database or encrypted configuration, and scoped to that one product.
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
      One enrollment, reusable by any agent that calls through {{site.ai_gateway}}.
  - aspect: "**Revocation/audit**"
    without: |
      Depends entirely on that connector vendor's own tooling. May or may not be centrally visible.
    with: |
      Uniform audit trail and revocation regardless of which agent triggered the original consent.
{% endtable %}
<!--vale on-->

Token Vault operates under the following constraints:
* Only the {{site.ai_gateway}} can request credentials from Token Vault, and that connection is locked down over mutual TLS (mTLS): both sides prove their identity with certificates.
* Agents and MCP clients never call Token Vault directly: if an agent needs a credential, it has to go through the {{site.ai_gateway}}.
* Token Vault never queries the corporate IdP about a user. It only fetches the IdP's public keys (JWKS) to verify that:
  * The token's signature is valid.
  * The token was issued by the IdP that an admin set as trusted for that directory.

### The {{site.ai_gateway}} role

{{site.ai_gateway}} acts as a bridge between the user and the third-party service.

You attach policies to the {{site.ai_gateway}}, which is where you scope and enforce call behaviors. Token Vault doesn't hold any policies, it only verifies whose token this is and returns the matching credential if one exists. For example, in a workflow configured with Okta as the IdP, the {{site.ai_gateway}}:

1. Receives a caller's Okta-issued token.
1. Presents it to Token Vault to request a credential for a specific provider.
1. After it gets one back, it injects the credential into the actual outbound request to the third-party service.

By default, {{site.ai_gateway}} sends the credential in an `Authorization: Bearer` header. To use a different header or a query parameter, set [`config.upstream.auth.token_vault.credential.outbound`](/ai-gateway/entities/ai-mcp-server/#schema-aigateway-mcpserver-config-upstream) on the AI MCP Server.

## Directory

The [{{site.identity}} directory](/identity/principals/) is the tenant boundary that scopes identities and access in Token Vault. To use Token Vault, you activate it in your directory with the `vault_enabled` flag.

The directory is also the encryption boundary for Token Vault.
After you enable Token Vault on your directory, register a public vault key on it by sending a `POST` request to the [`createVaultKey` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createVaultKey).
The vault key protects the credentials you store. See [Credential storage and encryption](/identity/token-vault/credentials/#credential-storage-and-encryption).
Trusted IdPs, providers, and credentials are all scoped to the directory, so no other directory can access them.

## Trusted IdP

The trusted IdP is what tells Token Vault whose tokens to trust. A {{site.identity}} admin configures a trusted IdP (for example, Okta) on the directory using the `issuer_url`, and optionally a `jwks_uri` ({{site.identity}} can automatically discover the `jwks_uri` from the IdP). 
A directory can have more than one trusted IdP, each identified by a unique `issuer_url`. Token Vault only accepts an IdP's tokens when you set `vault_access_enabled` to `true` on that trusted IdP (for example, your corporate IdP).

Token Vault verifies tokens and never queries the IdP about a user directly.
When it receives a token, it:

1. Checks that the token's signature matches the trusted IdP's published public keys, and confirms the IdP actually issued it. Only asymmetric signing algorithms (RS, PS, and ES families) are accepted.
1. Checks the token's expiry (`exp`) and not-before (`nbf`) claims.
1. Reads the subject already embedded in the token, to determine who it was issued to. By default, the subject is the `sub` claim.

Users don't need to exist in {{site.identity}} beforehand. Token Vault supports just-in-time (JIT) provisioning, also called automatic user provisioning, on its identity providers (IdPs). When `jit_provisioning_enabled` is `true` (the default) and no [{{site.identity}} principal](/identity/principals/) matches the token's issuer and subject, Token Vault creates one. Per-user credentials are stored for that principal.

To enable JIT provisioning in the {{site.konnect_short_name}} UI, go to **AI** > **Access Management** > **Identity Providers**, then create a new IdP or edit an existing one, and enable **Automatic user provisioning**.


To add a trusted IdP, send a `POST` request to the [`createTrustedIdp` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createTrustedIdp) endpoint. The `issuer_url` must be unique within the directory, so a `POST` reusing an existing issuer returns a `409`. The comparison ignores case and trailing slashes, so `https://example.com/` and `https://EXAMPLE.com` count as the same issuer. The request accepts the following body parameters:

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: param
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - param: "`issuer_url`"
    required: Yes
    description: |
      The IdP's issuer URL. Must use `https` and can't include a query string or fragment. Token Vault only trusts subject tokens whose `iss` claim matches this value.
  - param: "`jwks_uri`"
    required: No
    description: |
      Where Token Vault fetches the IdP's public keys to verify token signatures. Must use `https`. If you omit it, {{site.identity}} discovers it from the issuer's `/.well-known/openid-configuration` document when a token is exchanged, and caches the result. When you create the trusted IdP, {{site.identity}} only checks that it can retrieve the IdP's signing keys.
  - param: "`display_name`"
    required: No
    description: |
      A human-readable name for the IdP.
  - param: "`vault_access_enabled`"
    required: No
    description: |
      Whether Token Vault accepts tokens from this IdP. Defaults to `false`: set it to `true` to use the IdP with Token Vault.
  - param: "`jit_provisioning_enabled`"
    required: No
    description: |
      Whether {{site.identity}} creates a principal just in time for a token subject that doesn't match an existing principal. Defaults to `true`.
  - param: "`jit.mapping.identifier`"
    required: No
    description: |
      The token claim that identifies the user. Defaults to `sub`.
{% endtable %}

A `PUT` on the [`updateTrustedIdp` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/updateTrustedIdp) replaces the whole configuration, so omitted fields reset to their defaults. Use [`PATCH`](/api/konnect/kong-identity-principals/v2/#/operations/patchTrustedIdp) to change individual fields.
<!--vale on-->

## Providers

You connect third-party services by adding a provider to the {{site.identity}} Token Vault. This lets an organization centralize identities and shared connections in one place, instead of configuring each service separately in every agent or client.

{{site.identity}} provides templates to bind external services. The template supplies the third-party service's secret type, default OAuth endpoints, default scopes, and the credential placements the service supports.

To list the templates and their defaults, send a `GET` request to the [`listCredentialProviderTemplates` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/listCredentialProviderTemplates). You create a provider by sending a `POST` request to the [`createVaultProvider` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createVaultProvider) with the following fields:

* `template_name`: The provider template to bind, listed in the following table.
* `name`: The custom name for this provider. Use it to tell apart several providers built from the same template. Must be unique in the directory, and match `^[a-zA-Z0-9_-]+$`.

When you register an OAuth app with the third-party service, set its redirect URI to the {{site.ai_gateway}}'s `/_vault/callback` endpoint, for example `https://gateway.example.com/_vault/callback`. For a local data plane, use `http://localhost:8000/_vault/callback`.

The following provider templates are available:

<!--vale off-->
{% table %}
columns:
  - title: Provider type
    key: provider
  - title: Value (`template_name`)
    key: value
  - title: Required parameters
    key: param
rows:
  - provider: "OAuth authorization code providers"
    value: |
      * `github`
      * `slack`
      * `atlassian`
      * `google`
    param: |
      `client_id` and `client_secret` of an app you own in the third-party service.
  - provider: "OAuth authorization code providers hosted on your own account or workspace"
    value: |
      * `snowflake`
      * `databricks`
    param: |
      `client_id`, `client_secret`, `authorization_endpoint`, and `token_endpoint`, using your account or workspace URLs. The template doesn't supply usable endpoints.
  - provider: "OAuth authorization code providers that support dynamic client registration (DCR)"
    value: |
      * `atlassian-rovo`
      * `datadog` (requires PKCE)
      * `miro` (requires PKCE)
    param: |
      None. Don't send a `client_id`: set `dcr_enabled` (it defaults to `true` for templates that ship a registration endpoint, such as `datadog` and `miro`), and {{site.ai_gateway}} registers the client with the provider on first use.
  - provider: "OAuth authorization code provider that isn't in the catalog"
    value: "`custom-oauth`"
    param: |
      `client_id`, `client_secret`, `authorization_endpoint`, and `token_endpoint`.
  - provider: "Provider that authenticates with a pre-issued API key or token in a header or query parameter"
    value: "`static_secret`"
    param: |
      None. You store the secret as a credential after creating the provider. `client_id` and `client_secret` aren't allowed.
{% endtable %}
<!--vale on-->


## Credentials

The {{site.identity}} Token Vault stores the credentials that providers use to connect to third-party services. For details on credential types, encryption, enrollment, static secrets, and credential management, see [Token Vault credentials](/identity/token-vault/credentials/).

## Set up Token Vault

To set up Token Vault:

1. Enable it on the directory.
1. Add a trusted IdP.
1. Add your first provider (see [Get started with the {{site.identity}} Token Vault](/how-to/get-started-with-token-vault/)).
1. [Register a vault key](/how-to/get-started-with-token-vault/#register-a-vault-key) to start using the provider.

To disable a provider without deleting it, for example as a kill switch, send a `PATCH` request to the [`updateVaultProvider` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/updateVaultProvider) with `enabled: false`.

A [`PUT`](/api/konnect/kong-identity-principals/v2/#/operations/replaceVaultProvider) on the same endpoint also sets `enabled` to `false` if you omit it.


## Limitations

The following limitations apply to Token Vault:

* **Policy enforcement:** Token Vault isn't a policy enforcement point, only {{site.ai_gateway_name}} can enforce policies. Token Vault doesn't handle authorization logic.
* **Customer-managed encryption key:** You register a public key on the directory by sending a `POST` request to the [`createVaultKey` endpoint](/api/konnect/kong-identity-principals/v2/#/operations/createVaultKey) to encrypt Token Vault data. The key must be a PEM-encoded RSA (≥2048-bit) or EC (≥256-bit) key. The matching private key stays on the {{site.ai_gateway_name}}, so Kong can't decrypt stored credentials. A directory can hold up to 5 vault keys for rotation.
* **{{site.konnect_short_name}} only:** Token Vault isn't available for self-hosted/on-prem deployments. 
* **Unique issuer per trusted IdP:** Within a directory, each trusted IdP must have a distinct `issuer_url`.
* **No vault purge:** You can't disable Token Vault and delete all of its data in one step. Delete providers and credentials individually, or delete the directory.
