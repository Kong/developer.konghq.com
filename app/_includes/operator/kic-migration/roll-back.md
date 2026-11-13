If validation fails, restore the saved selector:

```bash
kubectl patch svc -n "${NAMESPACE}" "${PROXY_SERVICE}" --type json \
  --patch-file rollback-proxy-service.json
```

Then check traffic through the original address.

Keep the old installation and routing configuration until you accept the cutover.
After cleanup starts, restoring the selector might not be enough to roll back.
