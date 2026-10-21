```sh
curl --fail-with-body -sS \
  "https://$KONNECT_REGION.api.konghq.com/v1/mesh/control-planes/$CONTROL_PLANE_ID" \
  -H "Authorization: Bearer $KONNECT_TOKEN" | jq '{id, name, version}'
```

Continue only when `version` is `v3`. If it is `v2`, stop: changing its version is an upgrade,
not an installation step. Use the [migration guidance](/mesh/migrate-policies-to-3/) for an
existing control plane.
