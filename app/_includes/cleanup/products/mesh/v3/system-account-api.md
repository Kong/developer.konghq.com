Delete the `mesh-zone-1` system account:

```sh
curl --fail-with-body -sS -X DELETE \
  "https://global.api.konghq.com/v3/system-accounts/$ACCOUNT_ID" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```
