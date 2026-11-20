Delete the global control plane, which also removes its zones and mesh:

```sh
curl -X DELETE https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```

Delete the system account created for the zone token:

```sh
curl -X DELETE https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```
