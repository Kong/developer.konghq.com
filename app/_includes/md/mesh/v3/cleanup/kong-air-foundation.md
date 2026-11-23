1. Delete the `zone2` cluster:

   ```sh
   minikube delete -p mesh-zone-2
   ```

1. Delete `zone1` cluster:

   ```sh
   minikube delete -p mesh-zone
   ```

1. Delete the `kong-air-cp` global control plane.
   This also deletes `kong-air-mesh` and every resource on the global control plane:

   ```sh
   curl --fail-with-body -sS -X DELETE \
     "https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID" \
     -H "Authorization: Bearer $KONNECT_TOKEN"
   ```

1. Delete the `mesh-zone1` and `mesh-zone2` system accounts that the zones used to connect:

   ```sh
   curl --fail-with-body -sS -X DELETE \
     "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID" \
     -H "Authorization: Bearer $KONNECT_TOKEN"
   curl --fail-with-body -sS -X DELETE \
     "https://global.api.konghq.com/v3/system-accounts/$ZONE2_ACCOUNT_ID" \
     -H "Authorization: Bearer $KONNECT_TOKEN"
   ```
