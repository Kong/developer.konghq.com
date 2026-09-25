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
