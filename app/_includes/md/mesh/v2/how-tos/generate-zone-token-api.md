A zone isn't a standalone {{site.konnect_short_name}} resource. To provision one through the API, create a [system account access token](#how-does-a-zone-authenticate-to-the-global-control-plane) with the `Connector` role scoped to your control plane, then connect a zone control plane with that token. This is the same model that the [Terraform guide](/mesh/deploy-mesh-using-terraform-and-konnect/) automates.

1. Create a system account:

   ```sh
   curl -X POST https://global.api.konghq.com/v3/system-accounts \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "zone-1",
       "description": "Authentication for zone-1",
       "konnect_managed": false
     }'
   ```

   Export the returned account `id`:

   ```sh
   export ACCOUNT_ID='YOUR_SYSTEM_ACCOUNT_ID'
   ```

1. Assign the `Connector` role for your control plane to the system account:

   ```sh
   curl -X POST https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID/assigned-roles \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "role_name": "Connector",
       "entity_type_name": "Mesh Control Planes",
       "entity_id": "'"$CONTROL_PLANE_ID"'",
       "entity_region": "'"$KONNECT_REGION"'"
     }'
   ```

1. Generate an access token for the system account:

   ```sh
   curl -X POST https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID/access-tokens \
     -H "Authorization: Bearer $KONNECT_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "name": "zone-1",
       "expires_at": "2027-01-01T00:00:00Z"
     }'
   ```

   The response includes the `token` value, which is shown only once. Copy it now.

1. Export the token:

   ```sh
   export CONTROL_PLANE_TOKEN='YOUR_ZONE_TOKEN'
   ```
