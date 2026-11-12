Delete the `example-cp` control plane. This also removes its mesh configuration:

```sh
curl --fail-with-body -sS -X DELETE \
  "https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```
