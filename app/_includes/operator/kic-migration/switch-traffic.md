Before you change the existing Service selector, save it as a rollback patch.

Turn on `pipefail` so that the save command fails if `kubectl` fails:

```bash
set -o pipefail
```

Save the selector:

```bash
kubectl get svc -n "${NAMESPACE}" "${PROXY_SERVICE}" -o json \
  | jq -e '[{"op":"replace","path":"/spec/selector","value":.spec.selector}]' \
  > rollback-proxy-service.json
```

Check that the command succeeded and that `rollback-proxy-service.json` contains the original selector.

Point the Service at the replacement pods:

```bash
kubectl patch svc -n ${NAMESPACE} ${PROXY_SERVICE} --type json -p \
  '[{"op":"replace","path":"/spec/selector","value":{"gateway.networking.k8s.io/gateway-name":"kong-migrated"}}]'
```

Use the JSON `replace` operation.
A merge patch combines the old and new selectors.
The `gateway-name` label keeps the selector tied to the Gateway, even if {{ site.operator_product_name_short }} recreates the `DataPlane` resource.

Check that the Service endpoints point to the replacement pods:

```bash
kubectl get endpointslice -n ${NAMESPACE} -l kubernetes.io/service-name=${PROXY_SERVICE} \
  -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"\n"}{end}'
```

Repeat your application checks through the original client address.
Leave the old pods running so that existing connections can drain.
If you use an AWS NLB with IP targets, wait for the new targets to become healthy and for the old targets to drain before cleanup.
{% if include.aws_link %}For more information, see [AWS load balancer cutover](#aws-load-balancer-cutover).{% endif %}
