---
title: "{{site.base_gateway}} PostgreSQL OAuth2 authentication"
content_type: reference
layout: reference

breadcrumbs:
  - /gateway/

products:
  - gateway

works_on:
  - on-prem

min_version:
  gateway: '3.14'

tags:
  - database
  - authentication

description: Configure {{site.base_gateway}} to authenticate to PostgreSQL using OAUTHBEARER SASL and an OAuth access token.

related_resources:
  - text: PostgreSQL TLS configuration reference
    url: /gateway/postgresql-tls-reference/
  - text: "{{site.base_gateway}} Amazon RDS database authentication with AWS IAM"
    url: /gateway/amazon-rds-authentication-with-aws-iam/
  - text: Connect a {{site.base_gateway}} Azure PostgreSQL Server using Azure Managed Identity
    url: /gateway/azure-pg-authentication-with-azure-managed-identity/
  - text: "{{site.base_gateway}} Google Cloud Postgres database authentication with GCP IAM"
    url: /gateway/gcp-postgres-authentication/

faqs:
  - q: What must match between pg_hba.conf and the {{site.base_gateway}} configuration?
    a: |
      The `scope` value in `pg_hba.conf` must match the `pg_oauth_scope` {{site.base_gateway}} configuration parameter (environment variable `KONG_PG_OAUTH_SCOPE`). If they don't match, PostgreSQL will reject the token even if it is otherwise valid.
  - q: Why does my connection fail even though the token is valid?
    a: |
      The `pg_user` {{site.base_gateway}} configuration parameter (environment variable `KONG_PG_USER`) must be set to the PostgreSQL role name that the validator maps from the token. If they don't match, the connection will fail.
---

Starting from version 3.14, {{site.base_gateway}} supports connecting to [PostgreSQL 18](https://www.postgresql.org/about/news/postgresql-18-rc-1-released-3130/) using OAuth2 authentication via the [SASL OAUTHBEARER](https://datatracker.ietf.org/doc/html/rfc7628) mechanism and a [server-side validator](https://github.com/percona/pg_oidc_validator). This is a more secure alternative to password-based authentication that enables single sign-on (SSO) and centralized access management through any OIDC-compliant identity provider such as Okta, Azure AD, Google, or Keycloak.

## Architecture

The following diagram shows how {{site.base_gateway}} authenticates to PostgreSQL using OAUTHBEARER:

1. {{site.base_gateway}} obtains an OAuth access token from the IdP (using client_credentials or password grant)
2. {{site.base_gateway}} connects to PostgreSQL using OAUTHBEARER SASL mechanism, sending the token
3. PostgreSQL's OAuth validator plugin contacts the IdP to validate the token
4. The validator verifies the token's authenticity (issuer, signature, expiration) and extracts the user's identity, typically the `sub` claim, which is mapped to an existing PostgreSQL role
5. If the role exists and the token is valid, the connection succeeds

<!--vale off-->
{% mermaid %}
sequenceDiagram
    participant Kong as {{site.base_gateway}}
    participant IdP
    participant PG as PostgreSQL 18 (oauth validator)

    Kong->>IdP: 1. Request token
    IdP-->>Kong: 2. Return token
    Kong->>PG: 3. Connect with OAUTHBEARER (send access token)
    PG->>IdP: 4. Validate token
{% endmermaid %}
<!--vale on-->

The token-to-role mapping in step 4 is critical: a PostgreSQL role must exist that matches the identity the validator extracts from the token. Which claim is used and how it maps to a role is determined entirely by the validator library or cloud provider.

## Version requirements

<!--vale off-->
{% table %}
columns:
  - title: Component
    key: component
  - title: Minimum Version
    key: version
  - title: Notes
    key: notes
rows:
  - component: "{{site.base_gateway}}"
    version: "3.14+"
    notes: First version to support OAUTHBEARER SASL
  - component: PostgreSQL
    version: "**18+**"
    notes: First version to support OAUTHBEARER authentication
  - component: "[OAuth Validator](https://github.com/percona/pg_oidc_validator)"
    version: "-"
    notes: Required for self-managed PostgreSQL; cloud-managed services may have built-in support
  - component: IdP
    version: "-"
    notes: Any OIDC-compliant identity provider
{% endtable %}
<!--vale on-->

## SSL requirements

Because OAUTHBEARER transmits tokens in plaintext, SSL is required. When `pg_oauth_auth=on`, {{site.base_gateway}} automatically enforces `pg_ssl=on` and `pg_ssl_required=on`. PostgreSQL must also have SSL enabled or the connection will fail.

## PostgreSQL setup

### 1. Install an OAuth validator plugin

PostgreSQL 18 introduced OAuth support but delegates token validation entirely to third-party libraries, it does not implement token verification itself. Self-managed deployments therefore require a validator library configured via the `oauth_validator_libraries` parameter. Kong supports [pg_oidc_validator](https://www.percona.com/blog/postgresql-oidc-authentication-with-pg_oidc_validator/) from Percona. Install and configure it according to its documentation.

### 2. Configure postgresql.conf

```
ssl = on
ssl_cert_file = '<path_to_server_certificate>'
ssl_key_file = '<path_to_server_private_key>'

oauth_validator_libraries = 'pg_oidc_validator'
```

### 3. Configure pg_hba.conf

```
# TYPE   DATABASE  USER      ADDRESS  METHOD  OPTIONS
local    all       all                trust
host     all       postgres  all      trust
host     all       all       all      oauth   issuer=https://<idp-host>/realms/<realm> scope=openid
```

Rules are evaluated top-down, first match wins:

<!--vale off-->
{% table %}
columns:
  - title: Rule
    key: rule
  - title: Meaning
    key: meaning
rows:
  - rule: "`local all all trust`"
    meaning: Local Unix socket connections are trusted (no authentication)
  - rule: "`host all postgres all trust`"
    meaning: The `postgres` superuser can connect via TCP without authentication
  - rule: "`host all all all oauth ...`"
    meaning: All other TCP connections must authenticate via OAUTHBEARER, with the specified `issuer` and `scope`
{% endtable %}
<!--vale on-->

### 4. Create a database role matching the token identity

The validator determines how to map a token to a PostgreSQL role. For client credentials flow, the `sub` claim is typically set to the `client_id` by the IdP, so the role name usually matches the client ID. Refer to your validator library or cloud provider's documentation to confirm the expected format.

```sql
CREATE ROLE "<matched_identity>" WITH LOGIN;
```

## Kong configuration

### Token endpoint vs Discovery endpoint

{{site.base_gateway}} needs to know where to request tokens. There are two mutually exclusive ways to configure this:

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Description
    key: description
rows:
  - parameter: "`pg_oauth_token_endpoint`"
    description: The IdP's token endpoint URL directly. Use this when you know the exact URL.
  - parameter: "`pg_oauth_discovery_endpoint`"
    description: "The IdP's OIDC discovery URL (`.well-known/openid-configuration`). Kong will fetch this document and extract the `token_endpoint` automatically."
{% endtable %}
<!--vale on-->

One of the two is **required**. If both are set, `token_endpoint` takes precedence. Discovery mode is useful when you prefer not to hardcode the token endpoint, or when the IdP may change its endpoint URL.

### Token endpoint auth method

`pg_oauth_token_endpoint_auth_method` controls how {{site.base_gateway}} sends client credentials to the IdP's token endpoint:

<!--vale off-->
{% table %}
columns:
  - title: Value
    key: value
  - title: Behavior
    key: behavior
rows:
  - value: "`client_secret_post` (default)"
    behavior: Sends `client_id` and `client_secret` in the request body
  - value: "`client_secret_basic`"
    behavior: Sends credentials via HTTP Basic Authentication header
{% endtable %}
<!--vale on-->

Choose the method your IdP supports. Most IdPs support both; some (e.g., certain enterprise IdPs) may only accept one.

### Example 1: Client Credentials Grant (with token_endpoint)

This is the most common pattern for service-to-service authentication, where {{site.base_gateway}} uses `client_id` and `client_secret` to obtain a token.

{% navtabs "example-1" %}
{% navtab "Environment variables" %}
```bash
KONG_PG_HOST=127.0.0.1
KONG_PG_PORT=5432
KONG_PG_DATABASE=kong
KONG_PG_USER=<db_role>

KONG_PG_OAUTH_AUTH=on
KONG_PG_OAUTH_CLIENT_ID=<client_id>
KONG_PG_OAUTH_CLIENT_SECRET=<client_secret>
KONG_PG_OAUTH_TOKEN_ENDPOINT=https://<idp-host>/token
KONG_PG_OAUTH_SCOPE=openid
KONG_PG_OAUTH_GRANT_TYPE=client_credentials

KONG_PG_SSL_VERIFY=on
```
{% endnavtab %}
{% navtab "kong.conf" %}
```text
pg_host=127.0.0.1
pg_port=5432
pg_database=kong
pg_user=<db_role>

pg_oauth_auth=on
pg_oauth_client_id=<client_id>
pg_oauth_client_secret=<client_secret>
pg_oauth_token_endpoint=https://<idp-host>/token
pg_oauth_scope=openid
pg_oauth_grant_type=client_credentials

pg_ssl_verify=on
```
{% endnavtab %}
{% endnavtabs %}

### Example 2: Client Credentials Grant (with discovery_endpoint)

Use this variant when you prefer not to hardcode the token endpoint URL, {{site.base_gateway}} resolves it automatically from the OIDC discovery document.

{% navtabs "example-2" %}
{% navtab "Environment variables" %}
```bash
KONG_PG_HOST=127.0.0.1
KONG_PG_PORT=5432
KONG_PG_DATABASE=kong
KONG_PG_USER=<db_role>

KONG_PG_OAUTH_AUTH=on
KONG_PG_OAUTH_CLIENT_ID=<client_id>
KONG_PG_OAUTH_CLIENT_SECRET=<client_secret>
KONG_PG_OAUTH_DISCOVERY_ENDPOINT=https://<idp-host>/.well-known/openid-configuration
KONG_PG_OAUTH_SCOPE=openid
KONG_PG_OAUTH_GRANT_TYPE=client_credentials

KONG_PG_SSL_VERIFY=on
```
{% endnavtab %}
{% navtab "kong.conf" %}
```text
pg_host=127.0.0.1
pg_port=5432
pg_database=kong
pg_user=<db_role>

pg_oauth_auth=on
pg_oauth_client_id=<client_id>
pg_oauth_client_secret=<client_secret>
pg_oauth_discovery_endpoint=https://<idp-host>/.well-known/openid-configuration
pg_oauth_scope=openid
pg_oauth_grant_type=client_credentials

pg_ssl_verify=on
```
{% endnavtab %}
{% endnavtabs %}

### Example 3: Password Grant

Use this grant type when the IdP requires resource owner credentials.

{% navtabs "example-3" %}
{% navtab "Environment variables" %}
```bash
KONG_PG_HOST=127.0.0.1
KONG_PG_PORT=5432
KONG_PG_DATABASE=kong
KONG_PG_USER=<db_role>

KONG_PG_OAUTH_AUTH=on
KONG_PG_OAUTH_CLIENT_ID=<client_id>
KONG_PG_OAUTH_CLIENT_SECRET=<client_secret>
KONG_PG_OAUTH_TOKEN_ENDPOINT=https://<idp-host>/token
KONG_PG_OAUTH_SCOPE=openid
KONG_PG_OAUTH_GRANT_TYPE=password
KONG_PG_OAUTH_USERNAME=<username>
KONG_PG_OAUTH_PASSWORD=<password>

KONG_PG_SSL_VERIFY=on
```
{% endnavtab %}
{% navtab "kong.conf" %}
```text
pg_host=127.0.0.1
pg_port=5432
pg_database=kong
pg_user=<db_role>

pg_oauth_auth=on
pg_oauth_client_id=<client_id>
pg_oauth_client_secret=<client_secret>
pg_oauth_token_endpoint=https://<idp-host>/token
pg_oauth_scope=openid
pg_oauth_grant_type=password
pg_oauth_username=<username>
pg_oauth_password=<password>

pg_ssl_verify=on
```
{% endnavtab %}
{% endnavtabs %}

### Example 4: Password Grant with ADFS

ADFS (Active Directory Federation Services) typically uses password grant with a `resource` parameter to identify the target application, and may use a public client (no `client_secret`).

{% navtabs "example-4" %}
{% navtab "Environment variables" %}
```bash
KONG_PG_HOST=127.0.0.1
KONG_PG_PORT=5432
KONG_PG_DATABASE=kong
KONG_PG_USER=<db_role>

KONG_PG_OAUTH_AUTH=on
KONG_PG_OAUTH_CLIENT_ID=<client_id>
KONG_PG_OAUTH_TOKEN_ENDPOINT=https://<adfs-host>/adfs/oauth2/token
KONG_PG_OAUTH_GRANT_TYPE=password
KONG_PG_OAUTH_USERNAME=<domain\\user>
KONG_PG_OAUTH_PASSWORD=<password>
KONG_PG_OAUTH_RESOURCE=https://<database-resource-uri>

KONG_PG_SSL_VERIFY=on
```
{% endnavtab %}
{% navtab "kong.conf" %}
```text
pg_host=127.0.0.1
pg_port=5432
pg_database=kong
pg_user=<db_role>

pg_oauth_auth=on
pg_oauth_client_id=<client_id>
pg_oauth_token_endpoint=https://<adfs-host>/adfs/oauth2/token
pg_oauth_grant_type=password
pg_oauth_username=<domain\\user>
pg_oauth_password=<password>
pg_oauth_resource=https://<database-resource-uri>

pg_ssl_verify=on
```
{% endnavtab %}
{% endnavtabs %}

`pg_oauth_resource` is only sent with the `password` grant type. `pg_oauth_client_secret` can be omitted for ADFS public clients.

## Configuration parameters

<!--vale off-->
{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Default
    key: default
  - title: Values
    key: values
  - title: Description
    key: description
rows:
  - parameter: "`pg_oauth_auth`"
    default: "`off`"
    values: "`on` / `off`"
    description: "Enable OAUTHBEARER authentication. Automatically enables `pg_ssl` and `pg_ssl_required`."
  - parameter: "`pg_oauth_client_id`"
    default: "-"
    values: string
    description: OAuth client ID. Required.
  - parameter: "`pg_oauth_client_secret`"
    default: "-"
    values: string
    description: "OAuth client secret. Required for `client_credentials` grant."
  - parameter: "`pg_oauth_token_endpoint`"
    default: "-"
    values: URL
    description: "IdP token endpoint URL. One of `token_endpoint` or `discovery_endpoint` is required."
  - parameter: "`pg_oauth_discovery_endpoint`"
    default: "-"
    values: URL
    description: "OIDC discovery URL (`.well-known/openid-configuration`). Alternative to `token_endpoint`."
  - parameter: "`pg_oauth_scope`"
    default: "-"
    values: string
    description: "OAuth scope to request (e.g., `openid`)."
  - parameter: "`pg_oauth_audience`"
    default: "-"
    values: string
    description: OAuth audience parameter.
  - parameter: "`pg_oauth_grant_type`"
    default: "`client_credentials`"
    values: "`client_credentials` / `password`"
    description: OAuth grant type.
  - parameter: "`pg_oauth_token_endpoint_auth_method`"
    default: "`client_secret_post`"
    values: "`client_secret_post` / `client_secret_basic`"
    description: How to send client credentials to the IdP.
  - parameter: "`pg_oauth_username`"
    default: "-"
    values: string
    description: "Username. Required when `grant_type` is `password`."
  - parameter: "`pg_oauth_password`"
    default: "-"
    values: string
    description: "Password. Required when `grant_type` is `password`."
  - parameter: "`pg_oauth_resource`"
    default: "-"
    values: string
    description: OAuth resource parameter.
{% endtable %}
<!--vale on-->

{:.note}
> All parameters also have `pg_ro_oauth_*` variants for read-only replica connections.
