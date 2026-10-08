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
      * Client credentials
      * Authorization code, with optional PKCE and dynamic client registration (DCR)
  - case: "Federate identity"
    examples: |
      Use the Token Vault as a single broker for users authenticated with a corp IdP (like Okta), without provisioning them in {{site.identity}} first.
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
1. The Token Vault verifies the Okta token and uses its issuer (`iss`) and subject (`sub`) to identify the user. If the user has no GitHub credential yet, the Token Vault returns an enrollment URL, and the {{site.ai_gateway}} asks the user to connect their GitHub account before continuing.
1. The user approves access on GitHub's OAuth consent screen. The Token Vault exchanges the authorization code for a GitHub token and stores it for that user. The Okta token only identifies the user, it never becomes the stored credential.
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
* Only the {{site.ai_gateway_name}} can request credentials from the Token Vault, and that connection is locked down over mutual TLS (mTLS): both sides prove their identity with certificates.
* Agents and MCP clients never call the Token Vault directly: if an agent needs a credential, it has to go through the {{site.ai_gateway_name}}.
* The Token Vault never asks the corp IdP about a user. It only fetches the IdP's public keys (JWKS) to verify that:
  * The token's signature is valid.
  * The token was issued by the IdP that an admin set as trusted for that directory.

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

The trusted IdP is what tells the Token Vault whose tokens to trust. A {{site.identity}} admin configures a trusted IdP (such as Okta) on the directory using the `issuer_url`, and optionally a `jwks_uri` ({{site.identity}} can automatically discover the `jwks_uri` from the IdP). Each directory supports one trusted IdP, and the Token Vault only accepts its tokens when `vault_access_enabled` is set to `true`. The trusted IdP can be your corporate IdP, or the {{site.identity}} authorization server, for example when clients authenticate with an Identity Assertion JWT Authorization Grant (ID-JAG) issued by your corporate IdP.

The Token Vault acts as a verifier, not a caller. It never asks the IdP about a user directly. Instead, when it receives a token, it:

1. Checks that the token's signature matches the trusted IdP's published public keys, confirming the IdP actually issued it. Only asymmetric signing algorithms (RS, PS, and ES families) are accepted.
1. Checks the token's expiry (`exp`) and not-before (`nbf`) claims.
1. Reads the issuer (`iss`) and subject (`sub`) already embedded in the token, to determine who it was issued to.

Users don't need to exist in {{site.identity}} beforehand. When `jit_provisioning_enabled` is `true` (the default) and no [{{site.identity}} principal](/identity/principals/) matches the token's issuer and subject, the Token Vault creates one just in time. Per-user credentials are stored against that principal.

## Providers

You connect third-party services by adding a provider to the {{site.identity}} Token Vault. This lets an organization centralize identities and shared connections in one place, instead of configuring each service separately in every agent or client.

{{site.identity}} provides templates to bind external services. The template supplies the third-party service's secret type, default OAuth endpoints, default scopes, and credential placement. To list the templates and their defaults, send a `GET` request to `/v2/credential-provider-templates`. You create a provider by sending a `POST` request to the `/v2/directories/{directoryId}/vault/providers` endpoint with the following fields:

* `template_name`: The provider template to bind, listed in the following table.
* `name`: The custom name for this provider. Use it to tell apart several providers built from the same template. Must be unique in the directory, and match `^[a-zA-Z0-9_-]+$`.

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
      * `figma`
      * `datadog` (requires PKCE)
    param: |
      None. Don't send a `client_id`: the Token Vault registers the client with the provider at first use.
  - provider: "OAuth authorization code provider that isn't in the catalog"
    value: "`custom-oauth`"
    param: |
      `client_id`, `client_secret`, `authorization_endpoint`, and `token_endpoint`.
  - provider: "OAuth client credentials (two-legged) provider"
    value: "`client_credentials`"
    param: |
      `client_id`, `client_secret`, and `token_endpoint`.
  - provider: "Provider that authenticates with a pre-issued API key or token in a header"
    value: "`static_secret`"
    param: |
      None. You store the secret as a credential after creating the provider. `client_id` and `client_secret` aren't allowed.
{% endtable %}
<!--vale on-->


## Credentials

The {{site.identity}} Token Vault protects the credential, the actual secret (a token or a key) for connecting to a provider. The credential is encrypted at rest in the Token Vault. The encryption scope is the {{site.identity}} directory for which you enable the Token Vault. Each directory has its own Token Vault key, that it uses to encrypt secrets.

The credentials can be personal or shared across the organization. You define this with the `credential_type` field on the provider:

* `user` sets a personal credential, enrolled by each user.
* `shared` sets a credential shared across the directory, managed by an admin.

The allowed values and default depend on the provider's secret type:

<!--vale off-->
{% table %}
columns:
  - title: Secret type
    key: type
  - title: Default `credential_type`
    key: default
  - title: Allowed values
    key: allowed
rows:
  - type: "`authorization_code`"
    default: "`user`"
    allowed: "`user`, `shared` (an admin enrolls the shared credential)"
  - type: "`client_credentials`"
    default: "`shared`"
    allowed: "`shared`, `user`"
  - type: "`static_secret`"
    default: "`shared`"
    allowed: "`shared` only"
{% endtable %}
<!--vale on-->

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
1. **Creation**: At creation, {{site.identity}} stores the credential in the Token Vault. For `static_secret` providers, you generate the secret in the third-party service and store it in the Token Vault yourself. For OAuth-based providers, the OAuth consent flow creates the credential and stores it automatically.
1. **Refresh**: For OAuth-based providers, the Token Vault refreshes credentials automatically before they expire (see the provider's `refresh_buffer_seconds`), with locking, to prevent concurrent requests from consuming a refresh token. If a refresh fails while the stored token is still valid, the Token Vault keeps releasing the stored token.
1. **Deletion/Revocation**: You can revoke credentials independently of the provider itself. Admins can list and delete a user's credentials with the `/v2/directories/{directoryId}/principals/{principalId}/vault-credentials` endpoints. Deleting a credential doesn't delete the provider, but the user must re-enroll before an agent can call that provider on their behalf again.

The Token Vault never exposes back the credentials to the API that created them: it releases them to the {{site.ai_gateway}} for outbound calls without making the credentials accessible from any read endpoint.


## Credential enrollment

Credential enrollment is a one-time process where a user grants {{site.identity}} permission to act on their behalf with a third-party service. This is when the Token Vault creates the credential for the first time.

When you configure a provider (for example, GitHub), the Token Vault registers it as a service it knows how to talk to. It doesn't mean any user has actually authorized anything yet, since there are still no credentials to hand back for the Token Vault. The enrollment process follows these steps:

1. When a request comes in from the agent, the Token Vault returns an enrollment URL, valid for 10 minutes, to walk the user through the third-party service OAuth consent screen. The screen lists exactly the scopes the provider requested (for example, `repo` on GitHub).
1. When the user approves, the third-party service redirects back to the Token Vault's `callback` endpoint, handing over an authorization code.
1. The Token Vault exchanges the authorization code for the third-party service's access token and refresh token. This exchange happens only between the Token Vault and the third-party service, not through the agent.
1. The Token Vault writes a new credential row for the access token, encrypted with the directory's vault key and keyed to that combination of directory, provider, and user. This is the credential that the Token Vault releases to the {{site.ai_gateway}} on every future request.

Enrollment happens once per user and per provider, not per organization. If a second user wants to use GitHub with an agent, they need to go through enrollment, and get their own credentials stored in the Token Vault. What is shared across the organization is the provider configuration (Client ID, scopes, endpoints).

For providers that support dynamic client registration (DCR), such as `atlassian-rovo`, the Token Vault registers the OAuth client with the provider at first use, so you don't need to create an app in the provider's console.

### Shared credential enrollment

For a shared authorization code provider, an admin enrolls once on behalf of the directory. Send a `POST` request to the `/v2/directories/{directoryId}/vault/providers/{providerId}/credentials` endpoint without a `secret`. The Token Vault creates a `pending` credential and returns an `enrollment_url`. Open that URL and complete the provider's OAuth consent: the credential becomes `active` and the Token Vault releases it to any authorized caller.

Each `GET` on the credential returns a fresh `enrollment_url`, so you can re-enroll the shared account at any time.


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
Send a `POST` request to the `/v2/directories/{directoryId}/trusted-idps` endpoint. Each directory supports one trusted IdP, so a second `POST` returns a `409`:
<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/trusted-idps
status_code: 201
method: POST
body:
  issuer_url: https://acme.okta.com/oauth2/default
  jwks_uri: https://acme.okta.com/oauth2/default/v1/keys
  display_name: Okta
  vault_access_enabled: true
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
      Where the Token Vault fetches the IdP's public keys to verify token signatures. Must use `https`. If you omit it, {{site.identity}} discovers it from the issuer's `/.well-known/openid-configuration` document.
  - param: "`display_name`"
    required: No
    description: |
      A human-readable name for the IdP.
  - param: "`vault_access_enabled`"
    required: No
    description: |
      Whether the Token Vault accepts tokens from this IdP. Defaults to `false`: set it to `true` to use the IdP with the Token Vault.
  - param: "`jit_provisioning_enabled`"
    required: No
    description: |
      Whether {{site.identity}} creates a principal just in time for a token subject that doesn't match an existing principal. Defaults to `true`.
{% endtable %}

`PUT` on `/v2/directories/{directoryId}/trusted-idps/{trustedIdpId}` replaces the whole configuration, so omitted fields reset to their defaults. Use `PATCH` to change individual fields.
<!--vale on-->
{% endnavtab %}
{% navtab "Check configured trusted IdPs" %}

To see which IdPs the Token Vault trusts for this directory, send a `GET` request to the same endpoint:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/trusted-idps
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
  client_id: $GITHUB_CLIENT_ID
  client_secret: $GITHUB_CLIENT_SECRET
  scopes:
    - repo
    - read:user
{% endkonnect_api_request %}
<!--vale on-->

For OAuth providers, register the Token Vault callback URL (`https://vault.<konnect-host>/v2/callback`) in the third-party app that issued the client ID and secret.


To disable a provider without deleting it, for example as a kill switch, send a `PATCH` request to `/v2/directories/{directoryId}/vault/providers/{providerId}` with `enabled: false`. A `PUT` on the same endpoint also sets `enabled` to `false` if you omit it.

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

### Store a static secret

A provider built on the `static_secret` template doesn't run an OAuth flow. You generate the credential yourself in the third-party service, for example an API key or a personal access token, then store it on the provider. The credential belongs to the directory instead of to an individual principal, so a `static_secret` provider only accepts `credential_type` set to `shared`, which is also the default.

Start by creating the provider. For `static_secret`, send only `template_name` and `name`, and optionally `credential_type` and `base_url`. {{site.identity}} rejects `client_id` and `client_secret` with a `400` for this template:

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
    required: No
    description: |
      Must be `shared` for `static_secret` providers, and defaults to `shared`. A shared credential is released to any authorized caller instead of being enrolled per principal.
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

A shared provider can hold one default credential and any number of credentials with a `selector`. A second credential without a selector returns a `409`. To rotate the secret, update the existing credential instead of creating another one.

#### Select a shared credential per principal

To release different shared credentials to different callers, for example one API key per team, add a `selector` and a `priority` to the credential:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials
status_code: 201
method: POST
headers:
  - 'Content-Type: application/json'
body:
  secret: $TEAM_SECRET
  selector: '"$GROUP_ID" in principal.groups'
  priority: 10
{% endkonnect_api_request %}
<!--vale on-->

* `selector` is a CEL expression (up to 1,024 characters) evaluated against the calling principal. It can use `principal.id`, `principal.display_name`, `principal.groups` (group IDs, including nested groups), and `principal.metadata`.
* `priority` is required with a selector, and not allowed without one. Each priority must be unique on the provider, otherwise the request returns a `409`.

When the {{site.ai_gateway_name}} requests a credential, the Token Vault evaluates the selectors in ascending priority order and releases the first match. If no selector matches, it releases the default credential. If a selector fails to evaluate, the request fails instead of falling back to the next credential.

{% navtabs "manage static secret" %}
{% navtab "Check stored credentials" %}

To list the credential metadata for a provider, send a `GET` request to the same endpoint. The response contains the credential metadata (ID, `selector`, `priority`, `status`, and timestamps), never the value:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials
status_code: 200
method: GET
{% endkonnect_api_request %}
<!--vale on-->
{% endnavtab %}
{% navtab "Rotate the secret" %}

To replace the stored value, send a `PUT` request to the `/v2/directories/{directoryId}/vault/providers/{providerId}/credentials/{credentialId}` endpoint. This operation only updates an existing credential, and returns a `404` when the credential doesn't exist for this provider. The response contains the updated credential metadata, never the value:

<!--vale off-->
{% konnect_api_request %}
url: /v2/directories/$DIRECTORY_ID/vault/providers/$PROVIDER_ID/credentials/$CREDENTIAL_ID
status_code: 200
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
* **One trusted IdP per directory:** Each directory supports a single trusted IdP for the Token Vault.
* **Credential quota:** By default, each provider holds up to 100 credentials, counting both shared and per-user credentials.
* **No vault purge:** You can't disable the Token Vault and delete all of its data in one step. Delete providers and credentials individually, or delete the directory.
