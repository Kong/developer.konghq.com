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
    - konnect/kong-identity

related_resources:
  - text: "{{site.identity}} authorization servers, claims, scopes, and clients"
    url: /identity/auth-servers/
  - text: Principals and directories
    url: /identity/principals/

faqs:
  - q: "Why use the {{site.identity}} Token Vault instead of connectors in LLM services?"
    a: |
      Connectors are client-owned: each time a user needs to connect an LLM to a service, they need to set up a connector inside each service. The Token Vault makes the Gateway sit in front of any client. You can use different agents with a single credential store, with a way to revoke access locally. Using the Token Vault prevents agents from accessing authorization tokens and provides a way of federating identities around corp IdP like Okta.  
---


The {{site.identity}} Token Vault is a {{ site.konnect_short_name }} built-in credential broker. 
It stores your users' credentials for third-party upstream services (such as GitHub, Slack, 
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
      * Static API keys
      * Client-credentials
      * Authorization code
  - case: "Federate identity"
    examples: |
      Use the Token Vault as a single broker for different trust chains:

      * Standard OAuth2 with corp IdP (like Okta)
      * Token exchange (ID-JAG)
  - case: "Enforce auth governance"
    examples: |
      * Disable a provider for enterprise kill-switch
      * Audit credential releases without logging the credential itself
{% endtable %}
<!--vale on-->


## How the token vault works

The following diagram shows how the {{site.identity}} Token Vault works on top of the following setup:
* Okta as corp IdP
* Claude Code as the agent, configured with an {{site.ai_gateway}} MCP server
* GitHub as the third-party service
* {{site.identity}} Token Vault as credentials broker
* {{site.ai_gateway}} as the token handler between Okta and the Token Vault

In this scenario:
1. A user authenticates to Okta, which generates a token.
1. The {{site.ai_gateway}} captures the token and hands it to the Token Vault.
1. The first time the {{site.ai_gateway}} detects the user on GitHub, it requires them to connect their GitHub account before continuing.
1. The Token Vault stores the credentials it extracts from the verified Okta token.
1. Claude Code can use the `tools/list` from the GitHub MCP: the user can now interact with GitHub from Claude Code.

{% include diagrams/token-vault.md %}


The following table shows what using the Token Vault brings to your authentication setup and flows:

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
      One enrollment, reusable by any agent that calls through {{site.ai_gateway_name}}.
  - aspect: "**Revocation/audit**"
    without: |
      Depends entirely on that connector vendor's own tooling. May or may not be centrally visible.
    with: |
      Uniform audit trail and revocation regardless of which agent triggered the original consent.
{% endtable %}
<!--vale on-->

Key facts:
* Only the {{site.ai_gateway_name}} can call the Token Vault, and that connection is locked down over mutual TLS (mTLS): both sides prove their identity with certificates.
* Agents and MCP clients never call the Token Vault directly: if an agent needs a credential, it has to go through the {{site.ai_gateway_name}}.
* The Token Vault never calls the corp IdP; it uses the IdP's public keys (JWKS) to verify that:
  * The token's signature is valid.
  * The token was issued by an IdP the {{site.ai_gateway_name}} set as trusted for that directory.

### The {{site.ai_gateway}} role

{{site.ai_gateway}} acts as a bridge between the user and the third-party service, as the sole runtime that calls the {{site.identity}} Token Vault. Agents and MCP clients never call the Token Vault directly. No matter which agent a user is running, the Token Vault only ever interacts with {{site.ai_gateway}}, never with the agent or the MCP server itself.

You attach policies to the {{site.ai_gateway}}, which is where you scope and enforce call behaviors. The Token Vault doesn't hold any policy, it only verifies whose token this is and hands back the matching credential if one exists. For example, in a workflow configured with Okta as the IdP, the {{site.ai_gateway}}:

1. Receives a caller's Okta-issued token.
1. Presents it to the Token Vault to request a credential for a specific provider.
1. Once it gets one back, injects the credential into the actual outbound request to the third-party service (for example, as a header, for providers that support it).

## Directory

The [{{site.identity}} directory](/identity/principals/) is the tenant boundary that scopes everything else in the Token Vault. To use the Token Vault, you activate it in your directory with the `vault_enabled` flag.

The directory is also the vault's encryption boundary. After enabling the vault in your directory, {{site.identity}} generates an encryption key to protect the credentials you store under it. Your {{site.identity}} directory is the equivalent of your "organization account", and enabling the Token Vault gives that account a locked workspace, with everything in it (trusted IdPs, connected third-party services, whose tokens it stores) scoped to that organization.

## Trusted IdP

The trusted IdP is what tells the Token Vault whose tokens to trust. A {{site.identity}} admin configures a trusted IdP (such as Okta) on the Token Vault using the `issuer_url`, and optionally a `jwks_uri` ({{site.identity}} can automatically discover the `jwks_uri` from the IdP).

The trusted IdP configuration is completely independent of the {{site.identity}} login system: the Token Vault doesn't need any identity to be already resolved as a [{{site.identity}} principal](/identity/principals/) to work. The Token Vault acts as a verifier, not a caller. It never asks the IdP anything directly. Instead, when it receives a token, it:

1. Checks that the token's signature matches the trusted IdP's published public keys, confirming the IdP actually issued it.
1. Reads the issuer (`iss`) and subject (`sub`) already embedded in the token, to determine who it was issued to.

## Providers

You connect third-party services by adding a provider to the {{site.identity}} Token Vault. This lets an organization centralize identities and shared connections in one place, instead of configuring each service separately in every agent or client.

## Credentials

The {{site.identity}} Token Vault protects the credential, the actual secret (a token or a key) for connecting to a provider. The credential is encrypted at rest in the Token Vault. The encryption scope is the {{site.identity}} directory for which you enable the Token Vault. Each directory has its own Token Vault key, that it uses to encrypt secrets.

The credentials can be personal or shared across the organization. You define this with the flag `credential_type`:

* `user` (default value) sets a personal token.
* `shared` sets a shared secret (required for `static_secret` providers).

<!--
Can the user set a shared secret for other providers, like GitHub or Slack?
-->

### Credential storage and encryption

The Token Vault stores credentials using envelope encryption, with two layers:

* **Vault key:** One per directory, generated when you enable the vault, acts as a master key for the organization's Token Vault. Kong stores and manages that master key, not the Token Vault user. 
* **Data key:** One per credential, encrypts the credential's value.

With envelope encryption, the vault key also encrypts each data key, providing a double layer of protection. If one secret gets leaked, the leak only impacts that specific secret, while the whole vault remains safe.

The Token Vault stores each credential in its own row, and binds the encrypted credential to the row it belongs to. This ensures no credential can move between rows, and prevents row-based tampering, where someone could copy an encrypted credential from one row into another and have it decrypt in a row it doesn't belong to.

A credential's value never comes back through APIs. While read endpoints return metadata (IDs, timestamps, status), they never return the actual token or key value.

### Auditing

Every credential lookup gets logged and emits a structured record covering successful outcomes (like credential releases or required enrollments). The audit trail captures the full pattern of who's asking for what. The following table lists what's logged and what isn't:

<!--vale off-->
{% feature_table %}
item_title: Audit record field
columns:
  - title: Description
    key: description
  - title: Included in audit record
    key: logged
features:
  - title: "`directory`"
    description: Which organization's directory the credential request belongs to.
    logged: true
  - title: "`provider`"
    description: Which third-party service the credential was requested for (for example, GitHub or Slack).
    logged: true
  - title: "secret type"
    description: The kind of secret involved (for example, OAuth token or static secret).
    logged: true
  - title: "credential type"
    description: Whether the credential is user-scoped or shared.
    logged: true
  - title: "calling gateway"
    description: Which {{site.ai_gateway_name}} instance made the request.
    logged: true
  - title: "subject"
    description: The identity the request was made on behalf of.
    logged: true
  - title: "decision"
    description: The outcome of the request — credential released, or enrollment required.
    logged: true
  - title: "secret values"
    description: The actual contents of any stored credential.
    logged: false
  - title: "released tokens"
    description: The token handed to {{site.ai_gateway_name}} for the outbound call.
    logged: false
  - title: "client secrets"
    description: OAuth client secrets configured on a provider.
    logged: false
  - title: "refresh tokens"
    description: Tokens used to renew an expired access token.
    logged: false
  - title: "OAuth codes"
    description: Authorization codes exchanged during enrollment.
    logged: false
{% endfeature_table %}
<!--vale on-->

### OAuth-based credential lifecycle

A credential moves through the following stages, depending on the action a user performs:

1. **Enrollment**: When no credentials exist yet, the first-time flow returns an enrollment URL instead of a token.
1. **Creation**: At creation the credential is stored in the Token Vault. Two flows exist to create credentials: for `static_secret`, a separate provider creates it and you store it manually in the Token Vault; for all other providers, the OAuth consent flow creates the secret and stores it automatically.
1. **Refresh**: For OAuth-based providers, the Token Vault can refresh credentials automatically, with locking, to prevent concurrent requests from consuming a refresh token.
1. **Deletion/Revocation**: You can revoke credentials independently of the provider itself. Deleting a credential doesn't delete the provider, but the user must re-enroll before an agent can call that provider on their behalf again.

The Token Vault never exposes back the credentials to the API that created them: it releases them to the {{site.ai_gateway}} for outbound calls without making the credentials accessible from any read endpoint.


## Credential enrollment

Credential enrollment is a one-time process where a user grants {{site.identity}} permission to act on their behalf with a third-party service. This is when the Token Vault creates the credential for the first time.

When you configure a provider (for example, GitHub), the Token Vault registers it as a service it knows how to talk to. It doesn't mean any user has actually authorized anything yet, since there are still no credentials to hand back for the Token Vault. The enrollment process follows these steps:

1. When a request comes in from the agent, the Token Vault returns an enrollment URL, valid for 10 minutes, to walk the user through the third-party service OAuth consent screen. The screen lists exactly the scopes the provider requested (for example, `repo` on GitHub).
1. When the user approves, the third-party service redirects back to the Token Vault's `callback` endpoint, handing over an authorization code.
1. The Token Vault exchanges the authorization code for the third-party service's access token and refresh token. This exchange happens only between the Token Vault and the third-party service, not through the agent.
1. The Token Vault writes a new credential row for the access token, encrypted with the directory's vault key and keyed to that combination of directory, provider, and user. This is the credential that the Token Vault releases to the {{site.ai_gateway}} on every future request.

Enrollment happens once per user and per provider, not per organization. If a second user wants to use GitHub with an agent, they need to go through enrollment, and get their own credentials stored in the Token Vault. What is shared across the organization is the provider configuration (Client ID, scopes, endpoints).

## ID-JAG and Enterprise Managed Authorization

When an agent needs access to a third-party service (like GitHub), a human clicks through an OAuth consent screen once, and the Token Vault handles everything from there. However, there is a more automated way for corporate IdPs (like Okta) to directly vouch for an agent's access, skipping the manual consent step. The workflows you can implement depend on two factors:

* **Enterprise Managed Authorization (EMA):** Decides not only who the user is, but what they're allowed to access. Also called **Cross-App Access (XASS)** in Okta. 
* **Identity Assertion JWT Authorization Grant (ID-JAG):** A short-lived token, minted by whichever component in the chain supports ID-JAG, that grants a specific user access to specific resources.

How the Token Vault gets involved depends on which component of the authorization workflow (the IdP, the agent, the provider's authorization server) accepts ID-JAG. The following table presents possible combinations: 

<!--vale off-->
{% table %}
columns:
  - title: Corporate IdP
    key: idp
  - title: MCP client/Agent
    key: client
  - title: Provider's authorization server
    key: provider
  - title: Setup
    key: setup
  - title: Token Vault involved?
    key: vault
rows:
  - idp: "Supports ID-JAG"
    client: "Supports ID-JAG"
    provider: "Doesn't support ID-JAG"
    setup: |
      * **{{site.identity}}'s authorization server:** ID-JAG consumer.
      * **Client**:
        1. Exchanges its IdP token for an ID-JAG scoped to {{site.identity}}.
        1. Redeems it for a normal access token.
    vault: "No (bypassed)"
  - idp: "Doesn't support ID-JAG"
    client: "Not required"
    provider: "Supports ID-JAG"
    setup: |
      **Token Vault:** ID-JAG provider (mints and signs the ID-JAG itself on the upstream's behalf).
    vault: "Yes, this is the vault's role."
{% endtable %}
<!--vale on-->


## Set up the Token Vault

The following section shows API calls to set up and start using the Token Vault.

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
{% navtab "Check if the Token Vault is enabled" %}

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
      The IdP's issuer URL. The Token Vault only trusts subject tokens whose `iss` claim matches this value.
  - param: "`jwks_uri`"
    required: No
    description: |
      Where the Token Vault fetches the IdP's public keys to verify token signatures. If you omit it, {{site.identity}} discovers it from the issuer's `/.well-known/openid-configuration` document.
{% endtable %}
<!--vale on-->
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
<!--vale on-->

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

TBD?
<!-- Configure AI MCP Proxy to exchange the caller's token for the stored credential and inject it. -->

### Store a static secret

A provider built on the `static_secret` template doesn't run an OAuth flow. You generate the credential yourself in the third-party service, for example an API key or a personal access token, then store it on the provider. The credential belongs to the directory instead of to an individual principal, so a `static_secret` provider requires `credential_type` set to `shared`.

Start by creating the provider. For `static_secret`, send only `name`, `credential_type`, and optionally `base_url`. {{site.identity}} rejects `client_id` and `client_secret` with a `400` for this template:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  template_name: static_secret
  name: internal-api
  credential_type: shared
capture:
  - variable: PROVIDER_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

The request accepts the following body parameters:

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
  - param: "`template_name`"
    required: Yes
    description: |
      Set to `static_secret` for a provider that authenticates with a pre-issued credential.
  - param: "`name`"
    required: Yes
    description: |
      Your name for this provider. Use it to tell apart several providers built from the same template.
  - param: "`credential_type`"
    required: Yes
    description: |
      Must be `shared` for `static_secret` providers. A shared credential is released to any authorized caller instead of being enrolled per principal.
  - param: "`base_url`"
    required: No
    description: |
      Overrides the base URL that the template supplies.
{% endtable %}
<!--vale on-->

Then store the credential on that provider by sending a `POST` request to the `/v2/directories/{directoryId}/vault/providers/{providerId}/credentials` endpoint. {{site.identity}} encrypts the value at rest and never returns it from any read endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  secret: $STATIC_SECRET
capture:
  - variable: CREDENTIAL_ID
    jq: ".id"
{% endkonnect_api_request %}
<!--vale on-->

A shared provider holds at most one credential, so a second `POST` to this endpoint returns a `409`. To rotate the secret, update the existing credential instead of creating another one.

{% navtabs "manage static secret" %}
{% navtab "Check stored credentials" %}

To list the credential metadata for a provider, send a `GET` request to the same endpoint. The response contains the credential ID and its timestamps, never the value:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "Rotate the secret" %}

To replace the stored value, send a `PUT` request to the `/v2/directories/{directoryId}/vault/providers/{providerId}/credentials/{credentialId}` endpoint. This operation only updates an existing credential, and returns a `404` when the credential doesn't exist for this provider:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials/$CREDENTIAL_ID
status_code: 204
method: PUT
headers:
  - 'Content-Type: application/json'
body:
  secret: $NEW_STATIC_SECRET
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}
{% navtab "Delete the secret" %}

To remove the stored credential, send a `DELETE` request to the same endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials/$CREDENTIAL_ID
status_code: 204
method: DELETE
{% endkonnect_api_request %}
<!--vale on-->

{% endnavtab %}

{% endnavtabs %}

## Limitations

The Token Vault presents the following limitations:

* **Policy enforcement:** The Token Vault isn't a policy enforcement point, only {{site.ai_gateway_name}} can enforce policies. The Token Vault doesn't handle authorization logic.
* **Customer-managed encryption key (BYOK):** Kong manages the encryption keys that protect stored credentials. You can't bring or control your own.
* **{{site.konnect_short_name}} only:** The Token Vault isn't available for self-hosted/on-prem deployments. 
