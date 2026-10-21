Create a **new** control plane. Do not use this procedure to upgrade an existing deployment.
The API defaults to v2, so specify `version: v3` explicitly. The command exports the returned
control plane `id` as `CONTROL_PLANE_ID`:

```sh
export CONTROL_PLANE_ID=$(curl --fail-with-body -sS -X POST \
  "https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  -H 'Content-Type: application/json' \
  -d '{"name":"example-cp","version":"v3"}' | jq -r .id)
```

Confirm that the variable contains the control plane ID:

```sh
echo "$CONTROL_PLANE_ID"
```
