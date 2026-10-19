The zone uses a system account access token with the `Connector` role on this control plane.
This authenticates configuration exchange with {{site.konnect_short_name}}; it does not issue workload identities.

Create a system account and export its `id` as `ACCOUNT_ID`:

```sh
export ACCOUNT_ID=$(curl --fail-with-body -sS -X POST https://global.api.konghq.com/v3/system-accounts \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"mesh-zone-1","description":"Connect zone-1","konnect_managed":false}' | jq -r .id)
echo "$ACCOUNT_ID"
```

Assign the account its role:

```sh
curl --fail-with-body -sS -X POST \
  "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID/assigned-roles" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"role_name":"Connector","entity_type_name":"Mesh Control Planes","entity_id":"'"$CONTROL_PLANE_ID"'","entity_region":"'"$KONNECT_REGION"'"}'
```

Choose a future expiry allowed by your organization's token policy, then create the token and
export the returned `token` as `CONTROL_PLANE_TOKEN`:

```sh
export TOKEN_EXPIRES_AT='REPLACE_WITH_FUTURE_RFC3339_TIMESTAMP'
export CONTROL_PLANE_TOKEN=$(curl --fail-with-body -sS -X POST \
  "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID/access-tokens" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"zone-1","expires_at":"'"$TOKEN_EXPIRES_AT"'"}' | jq -r .token)
```

{{site.konnect_short_name}} returns the token only once. Store it securely and don't commit it to
source control.
