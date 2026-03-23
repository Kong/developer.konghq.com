---
title: Kong PostgreSQL OAUTHBEARER Authentication
content_type: reference
layout: reference
products:
  - gateway
works_on:
  - self-managed
description: Configure Kong Gateway to authenticate to PostgreSQL using OAUTHBEARER SASL and an OAuth access token.
---
## Introduction

[PostgreSQL 18](https://www.postgresql.org/about/news/postgresql-18-rc-1-released-3130/)) introduces a native OAuth2 authentication method based on the [SASL OAUTHBEARER](https://datatracker.ietf.org/doc/html/rfc7628) mechanism, by using a [server-side validator](https://github.com/percona/pg_oidc_validator).

Based on that, {{site.ee_product_name}} adds support for connecting to PostgreSQL 18 using OAuth2 authentication, starting from version 3.14.

## Architecture

```
┌──────┐    1. Request Token     ┌─────┐
│ Kong │ ──────────────────────> │ IdP │
│      │ <────────────────────── │     │
└──┬───┘    2. Return Token      └──┬──┘
   │                                │
   │ 3. Connect with OAUTHBEARER    │ 4. Validate Token
   │    (send access token)         │
   ▼                                │
┌─────────────────┐                 │
│ PostgreSQL 18   │ ────────────────┘
│ (oauth validator)│
└─────────────────┘
```

**Flow:**

1. Kong obtains an OAuth access token from the IdP (using client_credentials or password grant)
2. Kong connects to PostgreSQL using OAUTHBEARER SASL mechanism, sending the token
3. PostgreSQL's OAuth validator plugin contacts the IdP to validate the token
4. The validator verifies the token and maps it to a PostgreSQL role
5. If the role exists and the token is valid, the connection succeeds

**Key constraint:** A PostgreSQL role must exist that matches the identity the validator extracts from the token. How this mapping works (which claim, what format) is determined entirely by the validator plugin or cloud provider.

## Version Requirements

| Component | Minimum Version | Notes |
|-----------|----------------|-------|
| {{site.ee_product_name}} | 3.14+ | First version to support OAUTHBEARER SASL |
| PostgreSQL | **18+** | First version to support OAUTHBEARER authentication |
| [OAuth Validator](https://github.com/percona/pg_oidc_validator) | - | Required for self-managed PostgreSQL; cloud-managed services may have built-in support |
| IdP | - | Any OIDC-compliant identity provider |

## SSL Requirements

OAUTHBEARER transmits tokens over the connection, so SSL is mandatory. When `pg_oauth_auth=on`, Kong automatically forces `pg_ssl=on` and `pg_ssl_required=on`.

**PostgreSQL must be configured with SSL enabled.** If PostgreSQL does not have SSL configured, the connection will fail.

### 1. Install an OAuth validator plugin

Self-managed PostgreSQL 18 requires an `oauth_validator_libraries` plugin to validate tokens. Install and configure one according to your chosen plugin's documentation.

### 2. Configure postgresql.conf

```ini
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

| Rule | Meaning |
|------|---------|
| `local all all trust` | Local Unix socket connections are trusted (no authentication) |
| `host all postgres all trust` | The `postgres` superuser can connect via TCP without authentication |
| `host all all all oauth ...` | All other TCP connections must authenticate via OAUTHBEARER, with the specified `issuer` and `scope` |

{:.important}
> The `scope` value in `pg_hba.conf` must match the `pg_oauth_scope` Kong configuration parameter (environment variable `KONG_PG_OAUTH_SCOPE`). If they don't match, PostgreSQL will reject the token even if it is otherwise valid

### 4. Create a database role matching the token identity

The validator plugin determines how to map a token to a PostgreSQL role (e.g., which claim to use, how to match). A role must exist that satisfies the validator's mapping rules. Refer to your validator plugin or cloud provider's documentation for the expected role name format.

```sql
CREATE ROLE "<matched_identity>" WITH LOGIN;
```

{:.important}
> The `pg_user` Kong configuration parameter (environment variable `KONG_PG_USER`) must be set to this role name. Kong uses `pg_user` as the PostgreSQL username in the connection, and it must match the role that the validator maps from the token. If they don't match, the connection will fail.

## Kong Configuration

### Token endpoint vs Discovery endpoint

Kong needs to know where to request tokens. There are two mutually exclusive ways to configure this:

| Parameter | Description |
|-----------|-------------|
| `pg_oauth_token_endpoint` | The IdP's token endpoint URL directly. Use this when you know the exact URL. |
| `pg_oauth_discovery_endpoint` | The IdP's OIDC discovery URL (`.well-known/openid-configuration`). Kong will fetch this document and extract the `token_endpoint` automatically. |

One of the two is **required**. If both are set, `token_endpoint` takes precedence. Discovery mode is useful when you prefer not to hardcode the token endpoint, or when the IdP may change its endpoint URL.

### Token endpoint auth method

`pg_oauth_token_endpoint_auth_method` controls how Kong sends client credentials to the IdP's token endpoint:

| Value | Behavior |
|-------|----------|
| `client_secret_post` (default) | Sends `client_id` and `client_secret` in the request body |
| `client_secret_basic` | Sends credentials via HTTP Basic Authentication header |

Choose the method your IdP supports. Most IdPs support both; some (e.g., certain enterprise IdPs) may only accept one.

### Example 1: Client Credentials Grant (with token_endpoint)

The most common pattern for service-to-service authentication. Kong uses `client_id` + `client_secret` to obtain a token.

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

# pg_ssl and pg_ssl_required are automatically enabled when pg_oauth_auth=on
KONG_PG_SSL_VERIFY=on
```

### Example 2: Client Credentials Grant (with discovery_endpoint)

Same as above, but using OIDC discovery to automatically resolve the token endpoint.

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

### Example 3: Password Grant

Used when the IdP requires resource owner credentials.

```bash
# kong.conf or environment variables

KONG_PG_HOST=127.0.0.1
KONG_PG_PORT=5432
KONG_PG_DATABASE=kong
KONG_PG_USER=<db_role>

# Enable OAuth authentication
KONG_PG_OAUTH_AUTH=on
KONG_PG_OAUTH_CLIENT_ID=<client_id>
KONG_PG_OAUTH_CLIENT_SECRET=<client_secret>
KONG_PG_OAUTH_TOKEN_ENDPOINT=https://<idp-host>/token
KONG_PG_OAUTH_SCOPE=openid
KONG_PG_OAUTH_GRANT_TYPE=password
KONG_PG_OAUTH_USERNAME=<username>
KONG_PG_OAUTH_PASSWORD=<password>

# pg_ssl and pg_ssl_required are automatically enabled when pg_oauth_auth=on
# Optionally configure SSL verification
KONG_PG_SSL_VERIFY=on
```

### Example 4: Password Grant with ADFS

ADFS (Active Directory Federation Services) typically uses password grant with a `resource` parameter to identify the target application, and may use a public client (no `client_secret`).

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

> Note: `pg_oauth_resource` is only sent with the `password` grant type. `pg_oauth_client_secret` can be omitted for ADFS public clients.

## All Kong Configuration Parameters

| Parameter | Default | Values | Description |
|-----------|---------|--------|-------------|
| `pg_oauth_auth` | `off` | `on` / `off` | Enable OAUTHBEARER authentication. Automatically enables `pg_ssl` and `pg_ssl_required`. |
| `pg_oauth_client_id` | - | string | OAuth client ID. Required. |
| `pg_oauth_client_secret` | - | string | OAuth client secret. Required for `client_credentials` grant. |
| `pg_oauth_token_endpoint` | - | URL | IdP token endpoint URL. One of `token_endpoint` or `discovery_endpoint` is required. |
| `pg_oauth_discovery_endpoint` | - | URL | OIDC discovery URL (`.well-known/openid-configuration`). Alternative to `token_endpoint`. |
| `pg_oauth_scope` | - | string | OAuth scope to request (e.g., `openid`). |
| `pg_oauth_audience` | - | string | OAuth audience parameter. |
| `pg_oauth_grant_type` | `client_credentials` | `client_credentials` / `password` | OAuth grant type. |
| `pg_oauth_token_endpoint_auth_method` | `client_secret_post` | `client_secret_post` / `client_secret_basic` | How to send client credentials to the IdP. |
| `pg_oauth_username` | - | string | Username. Required when `grant_type` is `password`. |
| `pg_oauth_password` | - | string | Password. Required when `grant_type` is `password`. |
| `pg_oauth_resource` | - | string | OAuth resource parameter. |

> All parameters also have `pg_ro_oauth_*` variants for read-only replica connections.

