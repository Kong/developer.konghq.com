---
title: 'Vault Authentication'
name: 'Vault Authentication'

content_type: plugin
tier: enterprise
publisher: kong-inc
description: 'Add Vault authentication to your Services or Routes'

tags:
  - authentication
  - hashicorp-vault

products:
    - gateway

works_on:
    - on-prem

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional

icon: vault-auth.png

categories:
  - authentication

search_aliases:
  - vault-auth
  - HashiCorp Vault

related_resources:
  - text: Enable authentication with Vault in {{site.base_gateway}}
    url: /how-to/enable-vault-authentication/
  - text: Authentication in {{site.base_gateway}}
    url: /gateway/authentication/
  - text: Configure HashiCorp Vault as a vault backend
    url: /how-to/configure-hashicorp-vault-as-a-vault-backend/

min_version:
  gateway: '1.0'
---

Add authentication to a Gateway Service or Route with an access token and a secret token. 
Credential tokens are stored securely via [Vault](https://developer.hashicorp.com/vault). 

The credential lifecycle can be managed through the [Admin API](/api/gateway/admin-ee/), or independently via Vault.

## Token time-to-live (TTL)

When reading a token from Vault, {{site.base_gateway}} will search the KV value for the presence of a `ttl` field. When this field is present, {{site.base_gateway}} will respect the advisory value of the `ttl` field and store the value of the credential in the cache for only as long as the `ttl` field defines. This allows {{site.base_gateway}} to periodically refresh tokens created directly in Vault, outside of the Admin API.

## External token pairs

{{site.base_gateway}} can read access/secret token pairs that were created directly in Vault, outside of the {{site.base_gateway}} Admin API. Vault KV secret values must contain the following fields:

```
{
  access_token: {your-string}
  secret_token: {your-string}
  created_at: {your-date-integer}
  updated_at: {your-date-integer}
  ttl: {your-integer} # optional
  consumer: {
    id: {consumer-uuid}
  }
}
```

Additional fields within the secret are ignored. The key must be the `access_token` value; this is the identifier by which {{site.base_gateway}} queries the Vault API to fetch the credential data.

See the Vault documentation for [version 1](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v1) or [version 2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) for more information on the KV secrets engine.

`vault-auth` token pairs can be created with the [Vault HTTP API](https://developer.hashicorp.com/vault/api-docs) or the `vault write` command:

```bash
vault write kong-auth/foo - <<EOF
{
  "access_token": "foo",
  "secret_token": "supersecretvalue",
  "consumer": {
    "id": "ce67c25e-2168-4a09-81e5-e06187a2384f"
  },
  "ttl": 86400
}
EOF
```
