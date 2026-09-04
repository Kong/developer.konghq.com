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

### The {{site.ai_gateway}} role

{{site.ai_gateway}} acts as bridge between the user and the requests as the sole runtime that calls the {{site.identity}} Token Vault. Agents and MCP clients never call the Token Vault directly. No matter which agent a user is running, the Token Vault only interacts with {{site.ai_gateway}}, not from the agent or the MCP itself.

Policies applies to the {{site.ai_gateway}}, which allow to scope and enforce call behaviors. The Token Vault doesn't hold any policy, it only verifies whose token this is and hands back the matching credential if one exists. For example, in a workflow configured with Okta as the IdP, the {{site.ai_gateway}}:

1. Receives a caller's Okta-issued token.
1. Presents it to the Token Vault to request a credential for a specific provider.
1. Once it gets one back, injects the credential into the actual outbond request to the third-party service (for example, as a header, for providers that support it).

## Token Vault components

<!--
Lead with a table summarizing component / scope / purpose, then a subsection each.
-->

### Directory

The [{{site.identity}} directory](/identity/principals/) is the tenant boundary that scopes everything else in the Token Vault. To use the Token Vault, you activate it in your directory with the `vault_enabled` flag.

The directory is also the vault's encryption boundary. After enabling the vault in your directory, {{site.identity}} generates an encryption key to protect the credentials you store under it. Your {{site.identity}} directory is the equivalent of your "organisation account", and enabling the Token Vault gives that account a locked workspace, with everything in it (trusted IdPs, connected third-party services, whose tokens it stores) scoped to that organisation.

### Trusted IdP

The trusted IdP is what tells the Token Vault whose tokens to trust. A {{site.identity}} admin configures a trusted IdP (succh as Okta) on the Token Vault using the `issuer_url`, and optionally a `jwks_uri`({{site.identity}} can automatically discover the `jwks_uri` from the IdP).

The trusted IdP configuration is completely independent of {{site.identity}} login system: the Token Vault doesn't need any identity to be already resolved as a [{{site.identity}} principal](/identity/principals/) to work. The Token Vault acts as a verifier, not a caller. It never asks the IdP anything directly. Instead, when it receives a token, it:

1. Checks that the token's signature matches the trusted IdP's published public keys, confirming the IdP actually issued it.
1. Reads the issuer (`iss`) and subject (`sub`) already embedded in the token, to determine who it was issued to.

### Providers

You connect third-party services by adding a provider to the {{site.identity}} Token Vault. This allows organization to centralize identities and shared connections. 

### Credentials

The {{site.identity}} Token Vault protects the credential, the actual secret (a token or a key) for connecting to a provider. The credential is encrypted at rest in the Token Vault. The encryption scope is the {{site.identity}} directory for which you enable the Token Vault. Each directory has its own Token Vault key, that it uses to encrypt secrets.

The credentials can be personal or shared across the organization. You define this with the flag `credential_type`:

* `user` (default value) sets a personal token.
* `shared` sets a shared secret (required for `static_secret` providers).

<!--
Can the user set a shared secret for other providers, like GitHub or Slack?
-->

#### OAuth-based credentials lifecycle

A credential knows different stages depending on the action that a user executes:

1. **Enrollment**: When no credentials exist yet, the first-time flow returns an enrollment URL instead of a token.
1. **Creation**: At creation the credential is stored in the Token Vault. Two flows exist to create credentials: for `static_secret`, a separate provider creates it and you store it manually in the Token Vault; for all other providers, the OAuth consent flow creates the secret and stores it automatically.
1. **Refresh**: For OAuth-based providers, the Token Vault can refresh credentials automatically, with locking, to prevent concurrent requests from consuming a refresh token.
1. **Deletion/Revocation**: You can revoke credentials independently of the provider itself. Deleting a credential doesn't delete a provider, but creates a new re-enrollment from the user side.

The Token Vault never exposes back the credentials to the API that created them: it releases them to the {{site.ai_gateway}} for outbond calls without making the credentials accessible from any read endpoint.


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

## Set up the Token Vault

### Enable the vault on a directory

{% navtabs "enable token vault" %}
{% navtab "Activate the Token Vault" %}
Send a `PATCH` request to the `/v2/directories/{directoryId}` endpoint with `vault_enabled` set to `true`:
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: PATCH
body:
  vault_enabled: true
{% endkonnect_api_request %}
<!--vale on-->


`PATCH` is a partial update, so any field you omit keeps its current value. You only need to send `vault_enabled`.
{% endnavtab %}
{% navtab "Check if the Token Vault is enbaled" %}

To confirm the vault is enabled, send a `GET` request to the same endpoint and read the `vault_enabled` field from the response:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID
status_code: 200
method: GET
capture:
  - variable: VAULT_ENABLED
    jq: ".vault_enabled"
{% endkonnect_api_request %}
<!--vale on-->

Print the captured value. It returns `true` when the Token Vault is active on the directory:

```sh
echo $VAULT_ENABLED
```
{% endnavtab %}

{% endnavtabs %}

### Add a trusted IdP

{% navtabs "configure trusted idp" %}
{% navtab "Add a trusted IdP" %}
Send a `POST` request to the `/v2/directories/{directoryId}/vault/trusted-idps` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/trusted-idps
status_code: 201
method: POST
body:
  issuer_url: https://acme.okta.com/oauth2/default
  jwks_uri: https://acme.okta.com/oauth2/default/v1/keys
{% endkonnect_api_request %}
<!--vale on-->

The request accepts the following body parameters:

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
      The IdP's issuer URL. The Token Vault only trusts subject tokens whose `iss` claim matches this value.
  - param: "`jwks_uri`"
    required: No
    description: |
      Where the Token Vault fetches the IdP's public keys to verify token signatures. If you omit it, {{site.identity}} discovers it from the issuer's `/.well-known/openid-configuration` document.
{% endtable %}
{% endnavtab %}
{% navtab "Check configured trusted IdPs" %}

To see which IdPs the Token Vault trusts for this directory, send a `GET` request to the same endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/trusted-idps
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}

{% endnavtabs %}

### Add a provider

{% navtabs "register provider" %}
{% navtab "Add a provider" %}
Send a `POST` request to the `/v2/directories/{directoryId}/vault/providers` endpoint:
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 201
method: POST
body:
  template_name: github
  name: github-prod
{% endkonnect_api_request %}
<!--vale on-->

The request accepts the following body parameters:

{% table %}
columns:
  - title: Parameter
    key: param
  - title: Required
    key: required
  - title: Description
    key: description
rows:
  - param: "`template_name`"
    required: Yes
    description: |
      The provider template to bind. The template supplies the third-party service's OAuth endpoints, secret type, available scopes, and credential placement. Allowed values are:
      * `github` to add the GitHub provider.
      * `slack` to add the Slack provider.
      * `static_secret` to add a custom provider that authenticates via an API key/token in a header. Requires `secret_type` to be set as `shared`. 
  - param: "`name`"
    required: Yes
    description: |
      Your name for this provider. Use it to tell apart several providers built from the same template.
{% endtable %}

{% endnavtab %}
{% navtab "Check configured providers" %}

To list the providers registered for this directory, send a `GET` request to the same endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}

{% endnavtabs %}

### Enable credential injection on a route

<!-- Configure AI MCP Proxy to exchange the caller's token for the stored credential and inject it. -->

### Store a static secret

## Manage connected credentials

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

### Kong Identity authorization server as an ID-JAG consumer

<!--
When the corp IdP and MCP client speak ID-JAG but the upstream MCP server does not.
Client logs in to its IdP, exchanges the id_token for an ID-JAG scoped to
{{site.identity}} (RFC 8693), redeems it at {{site.identity}} (RFC 7523) for an access token,
and calls the gateway with that. The directory's trusted IdP is the {{site.identity}}
authorization server itself; from there the flow continues as described above.
-->

### Token Vault as an ID-JAG provider

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

<!--
## Flow

1. Generate a secret (like a PAT from a third-party service).
1. Store it in the vault.
1. Retrieve the provider's ID.
1. Add it to your gateway configuration and decK apply it.
-->