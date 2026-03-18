# Kong PostgreSQL OAUTHBEARER Authentication

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
| Kong Enterprise | 3.x+ | Requires pgmoon with OAUTHBEARER SASL support |
| PostgreSQL | **18** | First version to support OAUTHBEARER authentication |
| OAuth Validator | - | Required for self-managed PostgreSQL; cloud-managed services may have built-in support |
| IdP | - | Any OIDC-compliant identity provider |

## PostgreSQL Server Setup

> Cloud-managed PostgreSQL services (e.g., AWS RDS, Azure Database, GCP Cloud SQL) may have built-in OAUTHBEARER support with their own IdP integration. In that case, skip steps 1-2 and refer to your cloud provider's documentation.

### 1. Install an OAuth validator plugin (self-managed only)

Self-managed PostgreSQL 18 requires an `oauth_validator_libraries` plugin to validate tokens. Install and configure one according to your chosen plugin's documentation.

### 2. Configure postgresql.conf (self-managed only)

```ini
shared_preload_libraries = '<your_validator_plugin>'
oauth_validator_libraries = '<your_validator_plugin>'
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
| `local all all trust` | Local unix socket connections are trusted without authentication |
| `host all postgres all trust` | The `postgres` superuser can connect from any host without authentication (for admin/maintenance) |
| `host all all all oauth ...` | All other TCP connections must authenticate via OAUTHBEARER, with the specified `issuer` and `scope` |

### 4. Create a database role matching the token identity

The validator plugin determines how to map a token to a PostgreSQL role (e.g., which claim to use, how to match). A role must exist that satisfies the validator's mapping rules. Refer to your validator plugin or cloud provider's documentation for the expected role name format.

```sql
CREATE ROLE "<matched_identity>" WITH LOGIN;
```

## Kong Configuration

### Example 1: Client Credentials Grant

The most common pattern for service-to-service authentication. Kong uses `client_id` + `client_secret` to obtain a token.

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
KONG_PG_OAUTH_GRANT_TYPE=client_credentials

# pg_ssl and pg_ssl_required are automatically enabled when pg_oauth_auth=on
# Optionally configure SSL verification
KONG_PG_SSL_VERIFY=on
```

### Example 2: Password Grant

Used when the IdP requires resource owner credentials (e.g., some legacy setups).

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

## All Kong Configuration Parameters

| Parameter | Default | Description |
|-----------|---------|-------------|
| `pg_oauth_auth` | `off` | Enable OAUTHBEARER authentication |
| `pg_oauth_client_id` | - | OAuth client ID |
| `pg_oauth_client_secret` | - | OAuth client secret |
| `pg_oauth_token_endpoint` | - | IdP token endpoint URL |
| `pg_oauth_discovery_endpoint` | - | OIDC discovery URL (alternative to token_endpoint) |
| `pg_oauth_scope` | - | OAuth scope (e.g., `openid`) |
| `pg_oauth_audience` | - | OAuth audience parameter |
| `pg_oauth_grant_type` | `client_credentials` | `client_credentials` or `password` |
| `pg_oauth_token_endpoint_auth_method` | `client_secret_post` | How to send client credentials to IdP |
| `pg_oauth_username` | - | Username (required for password grant) |
| `pg_oauth_password` | - | Password (required for password grant) |
| `pg_oauth_resource` | - | OAuth resource parameter |

> All parameters also have `pg_ro_oauth_*` variants for read-only replica connections.
