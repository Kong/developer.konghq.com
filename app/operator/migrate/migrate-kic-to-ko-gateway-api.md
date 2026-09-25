---
title: "Migrate a Gateway API configuration to {{ site.operator_product_name }}"
description: "Migrate Gateway API routing from KIC to Kong Operator while preserving your existing Service and client address."
content_type: reference
layout: reference
products:
  - operator
breadcrumbs:
  - /operator/
  - /operator/migrate/migrate-kic-to-ko/
works_on:
  - on-prem
  - konnect
tags:
  - migration
related_resources:
  - text: "Migration overview"
    url: /operator/migrate/migrate-kic-to-ko/
  - text: "Migrate an Ingress configuration"
    url: /operator/migrate/migrate-kic-to-ko-ingress/
  - text: "Version compatibility"
    url: /operator/reference/version-compatibility/
  - text: "GatewayConfiguration reference"
    url: /operator/reference/custom-resources/#gatewayconfiguration
---

Migrate your existing Gateway API `HTTPRoute` resources to {{ site.operator_product_name }} while retaining the Service and address your clients use. Attach routes to both Gateways during validation, then detach the old Gateway after cutover.

This guide ends with an operator-managed gateway behind your retained Service, which you continue to manage. For installations using both APIs, start with the [migration overview](/operator/migrate/migrate-kic-to-ko/#if-you-use-both-apis).

## Before you begin

This guide assumes a DB-less installation deployed with `kong/kong` or `kong/ingress`, and uses an HTTP listener on port 80. The replacement gateway must be in the same namespace as the existing proxy Service. Adapt listeners and validation requests for HTTPS or other requirements.

You need administrative cluster access, Bash, Helm, `kubectl`, `jq`, and cert-manager. Back up your Kubernetes configuration and Helm values, use {{ site.kic_product_name }} {{ site.data.kic_latest.release }}, and ensure the cluster has capacity to run both installations.

Set the following values for your installation. Use `helm list` to find the existing release and chart version. Keep the current gateway image and choose a replica count that can serve your traffic.

```bash
export NAMESPACE=default
export RELEASE_NAME=kong
export KIC_CHART_VERSION='<installed-chart-version>'
export PROXY_SERVICE=kong-proxy
export GATEWAY_IMAGE='<current-image:tag>'
export GATEWAY_REPLICAS=2
export OLD_GATEWAY='<existing-gateway>'
export OLD_GATEWAY_CLASS='<existing-gateway-class>'
```

The new resources are named `kong-migrated`. If that name is already in use, choose another name throughout this guide. The route example assumes the HTTPRoute and both Gateways are in `$NAMESPACE`. For routes in other namespaces, set the parent reference namespace and configure the replacement listener to allow those namespaces. If you use GitOps, update the route manifests so reconciliation does not revert the migration changes.

## Preserve the existing Service

Keep the Service and its address when you later uninstall {{ site.kic_product_name_short }}. Apply `helm.sh/resource-policy: keep` through your existing Helm values so Helm records it in the release manifest. Use the tab for your installed chart.

{% navtabs "kic-chart" %}
{% navtab "`kong` chart" %}

Merge this setting into your existing `values.yaml`:

```yaml
proxy:
  annotations:
    helm.sh/resource-policy: keep
```

Apply the change:

```bash
helm upgrade -n ${NAMESPACE} ${RELEASE_NAME} kong/kong --version "${KIC_CHART_VERSION}" -f values.yaml
```

{% endnavtab %}
{% navtab "`ingress` chart" %}

Merge this setting into your existing `values.yaml`:

```yaml
gateway:
  proxy:
    annotations:
      helm.sh/resource-policy: keep
```

Apply the change:

```bash
helm upgrade -n ${NAMESPACE} ${RELEASE_NAME} kong/ingress --version "${KIC_CHART_VERSION}" -f values.yaml
```

{% endnavtab %}
{% endnavtabs %}

The upgrade should complete successfully with the existing chart version. Confirm the Service has the `helm.sh/resource-policy: keep` annotation using `kubectl get svc -n "$NAMESPACE" "$PROXY_SERVICE" -o yaml`.

Add the retained Service to the manifests you maintain. If you use GitOps, ensure it will preserve this Service and the selector you set during cutover.

## Install {{ site.operator_product_name }}

Install the operator alongside your existing installation:

```bash
helm repo update kong
helm upgrade --install kong-operator kong/kong-operator \
  -n kong-system \
  --create-namespace \
  --take-ownership \
  --set env.ENABLE_CONTROLLER_KONNECT=true \
  --set ko-crds.enabled=true \
  --set global.conversionWebhook.enabled=true \
  --set global.conversionWebhook.certManager.enabled=true
```

Confirm the operator pods are running with `kubectl get pods -n kong-system`. Complete any operator upgrades before cutover, and avoid operator restarts while changing routing resources.

## Create the replacement gateway

Create a separate Gateway and GatewayClass. Keep the existing Gateway, GatewayClass, and routing resources in place until cleanup.

Apply this configuration. It creates the `GatewayConfiguration`, `GatewayClass`, and `Gateway`, using your current image and the replica count you selected. The new Service is internal (`ClusterIP`), so this does not change client traffic.

```bash
cat <<EOF | kubectl apply -f -
kind: GatewayConfiguration
apiVersion: gateway-operator.konghq.com/{{ site.operator_gatewayconfiguration_api_version }}
metadata:
  name: kong-migrated
  namespace: ${NAMESPACE}
spec:
  dataPlaneOptions:
    deployment:
      replicas: ${GATEWAY_REPLICAS}
      podTemplateSpec:
        spec:
          containers:
          - name: proxy
            image: ${GATEWAY_IMAGE}
    network:
      services:
        ingress:
          type: ClusterIP
  controlPlaneOptions:
    cache:
      initSyncDuration: 30s
    controllers:
    - name: GWAPI_GATEWAY
      state: enabled
    - name: GWAPI_HTTPROUTE
      state: enabled
    - name: KONG_PLUGIN
      state: enabled
    - name: KONG_CONSUMER
      state: enabled
---
kind: GatewayClass
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong-migrated
spec:
  controllerName: konghq.com/gateway-operator
  parametersRef:
    group: gateway-operator.konghq.com
    kind: GatewayConfiguration
    name: kong-migrated
    namespace: ${NAMESPACE}
---
kind: Gateway
apiVersion: gateway.networking.k8s.io/v1
metadata:
  name: kong-migrated
  namespace: ${NAMESPACE}
spec:
  gatewayClassName: kong-migrated
  listeners:
  - name: http
    protocol: HTTP
    port: 80
EOF
```
{:.collapsible}

Wait for the Gateway to report `Programmed`:

```bash
kubectl wait -n "${NAMESPACE}" --for=condition=Programmed --timeout=300s gateway/kong-migrated
```

The replacement is ready for you to attach routes.

## Attach routes to both Gateways

An HTTPRoute is attached to a Gateway through `spec.parentRefs`. Add the replacement Gateway as another parent so both installations can serve the same route during validation.

For example, append `kong-migrated` to an existing route named `example-route`:

```bash
kubectl patch httproute example-route -n "${NAMESPACE}" --type json \
  -p '[{"op":"add","path":"/spec/parentRefs/-","value":{"kind":"Gateway","name":"kong-migrated"}}]'
```

This preserves the existing parent references. The route must already have a `parentRefs` list; check that `kong-migrated` is not already listed before applying or retrying the patch. If the old attachment uses `sectionName` or `port`, include the appropriate listener restriction in the new reference as well.

Repeat for every HTTPRoute attached to the old Gateway that you want to migrate. Confirm each route references both Gateways before validating the replacement. Keep the old parent references until cleanup.

## Validate the replacement

The new data plane has no external address, so reach it with a port-forward. Confirm the lookup below identifies exactly one Service belonging to `kong-migrated`; if you have other operator-managed data planes, set `INGRESS_SVC` to the correct Service name.

```bash
INGRESS_SVC=$(kubectl get svc -n "${NAMESPACE}" -l gateway-operator.konghq.com/managed-by=dataplane \
  -o jsonpath='{.items[?(@.spec.ports[0].port==80)].metadata.name}')
```

After confirming the Service name, start the port-forward:

```bash
kubectl port-forward -n "${NAMESPACE}" "svc/$INGRESS_SVC" 18000:80
```

In another terminal, exercise every hostname and path your configuration serves, and confirm that plugin behavior matches:

```bash
curl -i -H "Host: example.com" http://127.0.0.1:18000/
```

Check the response body, status code, and any headers your plugins add. Compare against the same request made to your existing gateway. Do not continue until every route matches.

## Switch traffic

Save the existing Service selector as a rollback patch before changing it:

```bash
set -o pipefail
kubectl get svc -n "${NAMESPACE}" "${PROXY_SERVICE}" -o json \
  | jq -e '[{"op":"replace","path":"/spec/selector","value":.spec.selector}]' \
  > rollback-proxy-service.json
```

Confirm the command succeeded and the file contains the original selector. Then point the Service at the replacement pods:

```bash
kubectl patch svc -n ${NAMESPACE} ${PROXY_SERVICE} --type json -p \
  '[{"op":"replace","path":"/spec/selector","value":{"gateway.networking.k8s.io/gateway-name":"kong-migrated"}}]'
```

Use the JSON `replace` operation as shown: a merge patch would combine the old and new selectors. The `gateway-name` label keeps the selector tied to the Gateway even if its DataPlane is recreated.

Check that the Service endpoints now identify the replacement pods:

```bash
kubectl get endpointslice -n ${NAMESPACE} -l kubernetes.io/service-name=${PROXY_SERVICE} \
  -o jsonpath='{range .items[*].endpoints[*]}{.targetRef.name}{"\n"}{end}'
```

Repeat your application checks through the original client address. Leave the old pods running so existing connections can drain. If you use an AWS NLB with IP targets, wait for the new targets to become healthy and old targets to drain before cleanup.

### Roll back

If validation fails, restore the saved selector and check traffic through the original address:

```bash
kubectl patch svc -n "${NAMESPACE}" "${PROXY_SERVICE}" --type json \
  --patch-file rollback-proxy-service.json
```

Keep the old installation and routing configuration until you accept the cutover. Restoring the selector alone may no longer be sufficient once cleanup begins.

## Retire the old installation

Wait until application checks pass through the existing address, old connections have drained, and load balancer target changes have converged. You can defer cleanup to a later maintenance window. Repeat your application checks between operations.

{:.warning}
> Cleanup ends the simple rollback path. Verify traffic after each operation and wait for routing to settle before continuing. Avoid operator restarts during cleanup.

1. Remove the old Gateway parent reference from each migrated route. For example, edit `example-route`:

   ```bash
   kubectl edit httproute example-route -n "${NAMESPACE}"
   ```

   In `spec.parentRefs`, remove only the entry or entries referencing the old Gateway. Keep `kong-migrated` and any unrelated parents. Repeat for the remaining routes and verify application traffic before continuing.

1. Confirm no routes still depend on the old Gateway, including any routes added during migration, then delete it:

   ```bash
   kubectl delete gateway -n "${NAMESPACE}" ${OLD_GATEWAY}
   ```

   Verify application traffic before continuing.

1. Delete the old `GatewayClass` only if no other Gateways use it:

   ```bash
   kubectl delete gatewayclass ${OLD_GATEWAY_CLASS}
   ```

   Verify application traffic before continuing.

1. Uninstall the Helm release:

   ```bash
   helm uninstall -n ${NAMESPACE} ${RELEASE_NAME}
   ```

   Helm reports the proxy Service as kept.

The migration is complete. Keep the retained Service in your managed manifests. {{ site.operator_product_name_short }} publishes the address of its own internal Service in resource status. Account for this if your tooling uses that field.

## Troubleshooting

| Symptom | Cause | Resolution |
|---|---|---|
| The Service has no endpoints after the cutover | The selector was applied with `--type merge`, which combined the old and new selectors | Reapply with `--type json` and a `replace` operation. |
| A second Gateway using the same `GatewayClass` never becomes programmed, and its ingress Service stays `<pending>` | The shared `GatewayConfiguration` pins a specific load balancer address, which cannot be assigned to two Services | Give each Gateway its own `GatewayConfiguration` if you pin addresses. |
| Requests return `404` for a few seconds during cleanup | Several Gateway API objects were changed while the operator was restarting, so the control plane pushed a configuration that was missing routes | Verify between each step, and raise `cache.initSyncDuration`. |
| Patching an `HTTPRoute` fails with `context deadline exceeded` calling `gwapi.validations.kong.konghq.com` | The operator's validating webhook was cold | Retry the patch. |

## Optional: Transfer address management

This optional operation transfers the address from your retained Service to the operator-managed Service. It is separate from the migration and depends on your load balancer platform.

At this point your address lives on a Service that is no longer managed by a chart or operator, and {{ site.operator_product_name_short }} publishes its own `ClusterIP` in the `status` of your Ingress and Gateway resources rather than your real address.

You can move the address onto the {{ site.operator_product_name_short }}-managed Service to get a fully operator-managed result. Whether this is worth doing depends entirely on your platform.

| Proxy Service type | Recommendation |
|---|---|
| `ClusterIP` or `NodePort` | **Not applicable.** Your clients resolve the Service by name and the new Service has a different name. Keep the Service you have. |
| Self-managed load balancer, such as MetalLB | **Optional.** Reassignment is a local operation and completes in well under a second. |
| AWS | **Do not attempt.** A load balancer's lifecycle is bound to the Service that created it and there is no reassignment operation. Deleting the Service deletes the load balancer, and a replacement comes up with a different hostname. Pinning elastic IPs requires releasing them from the old load balancer first. |
| Azure | **Do not attempt.** A static public IP cannot be attached to two Services at once, so the move is a release followed by a reassignment, and the reconciliation window runs from tens of seconds to minutes. |
| Other cloud providers | Confirm that your provider supports moving the address between Services before attempting this. If in doubt, keep the Service you have. |

Keeping the existing Service preserves the migration outcome. Continue managing its manifest yourself, and account for the different published status address in any tooling that consumes it.

If your platform supports it, request the address on the new Service **first** and let it stay pending, then release it from the old one. Doing it in this order gives the load balancer a waiting claimant the moment the address frees up.

1. Pre-arm the {{ site.operator_product_name_short }}-managed Service. Replace the annotation with the equivalent for your load balancer:

   ```bash
   kubectl patch gatewayconfiguration -n "${NAMESPACE}" kong-migrated --type merge -p \
     '{"spec":{"dataPlaneOptions":{"network":{"services":{"ingress":{
        "type":"LoadBalancer",
        "annotations":{"metallb.universe.tf/loadBalancerIPs":"192.0.2.10"}}}}}}}'
   ```

1. Wait for the new Service to appear as `LoadBalancer` with a pending address.

1. Release the address from the old Service:

   ```bash
   kubectl patch svc -n ${NAMESPACE} ${PROXY_SERVICE} --type json \
     -p '[{"op":"replace","path":"/spec/type","value":"ClusterIP"}]'
   ```

1. Confirm the new Service has taken the address, verify traffic, and then delete the old Service.
