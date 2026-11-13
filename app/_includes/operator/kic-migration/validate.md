The new data plane doesn't have an external address, so use a port-forward to reach it.

Find the data plane Service:

```bash
INGRESS_SVC=$(kubectl get svc -n "${NAMESPACE}" -l gateway-operator.konghq.com/managed-by=dataplane \
  -o jsonpath='{.items[?(@.spec.ports[0].port==80)].metadata.name}')
```

Check that `INGRESS_SVC` contains exactly one Service, and that it belongs to `kong-migrated`.
If you have other {{ site.operator_product_name }}-managed data planes, set `INGRESS_SVC` to the correct Service name.

Start the port-forward:

```bash
kubectl port-forward -n "${NAMESPACE}" "svc/$INGRESS_SVC" 18000:80
```

In another terminal, send requests for every hostname and path your configuration serves, and check that plugin behavior matches.
For example:

```bash
curl -i -H "Host: example.com" http://127.0.0.1:18000/
```

Check the response body, status code, and any headers that your plugins add.
Compare each response with the same request sent to your existing gateway.
Don't continue until every route matches.
