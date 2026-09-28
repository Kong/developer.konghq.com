{% if include.create_control_plane %}
## Create a Mesh 3 global control plane

Create a **new** control plane. Do not use this procedure to upgrade an existing deployment.
The API defaults to v2, so specify `version: v3` explicitly:

```sh
curl --fail-with-body -sS -X POST \
  "https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"example-cp","version":"v3"}'
```

Export the returned control plane `id`:

```sh
export CONTROL_PLANE_ID='YOUR_CONTROL_PLANE_ID'
```
{% endif %}

## Give the zone credentials to connect

The zone uses a system account access token with the `Connector` role on this control plane.
This authenticates configuration exchange with Konnect; it does not issue workload identities.

Create a system account:

```sh
curl --fail-with-body -sS -X POST https://global.api.konghq.com/v3/system-accounts \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"mesh-zone-1","description":"Connect zone-1","konnect_managed":false}'
export ACCOUNT_ID='YOUR_SYSTEM_ACCOUNT_ID'
```

Replace `YOUR_SYSTEM_ACCOUNT_ID` with the returned `id`, then assign its role:

```sh
curl --fail-with-body -sS -X POST \
  "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID/assigned-roles" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"role_name":"Connector","entity_type_name":"Mesh Control Planes","entity_id":"'"$CONTROL_PLANE_ID"'","entity_region":"'"$KONNECT_REGION"'"}'
```

Choose a future expiry allowed by your organization's token policy and create the token:

```sh
export TOKEN_EXPIRES_AT='REPLACE_WITH_FUTURE_RFC3339_TIMESTAMP'
curl --fail-with-body -sS -X POST \
  "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID/access-tokens" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"zone-1","expires_at":"'"$TOKEN_EXPIRES_AT"'"}'
export CONTROL_PLANE_TOKEN='YOUR_SYSTEM_ACCOUNT_ACCESS_TOKEN'
```

Copy the returned `token` into `CONTROL_PLANE_TOKEN`. It is shown only once. Store it securely
and do not commit it to source control.
