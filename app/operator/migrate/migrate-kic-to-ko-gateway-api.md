---
title: "Migrate a Gateway API configuration to {{ site.operator_product_name }}"
description: "Migrate Gateway API routing from {{ site.kic_product_name }} to {{ site.operator_product_name }} while preserving your existing Service and client address."
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

Migrate your existing Gateway API routes from {{ site.kic_product_name }} to {{ site.operator_product_name }} while you keep the Service and address your clients use.
During validation, you attach each route to both the old Gateway and the replacement Gateway.
After cutover, you detach the routes from the old Gateway.

When you finish this guide, a {{ site.operator_product_name }}-managed gateway serves traffic behind your retained Service.
You continue to manage that Service yourself.
If you use both Ingress and Gateway API resources, start with the [migration overview](/operator/migrate/migrate-kic-to-ko/#if-you-use-both-apis).

## Supported route types

The examples in this guide use `HTTPRoute`.
{{ site.operator_product_name_short }} also supports other Gateway API route types on on-prem gateways, depending on its version:

{% table %}
columns:
  - title: Route type
    key: route
  - title: Minimum {{ site.operator_product_name_short }} version
    key: version
rows:
  - route: "`HTTPRoute`"
    version: All supported versions
  - route: "`TLSRoute`"
    version: "2.2"
  - route: "`GRPCRoute`, `TCPRoute`, `UDPRoute`"
    version: "2.3"
{% endtable %}

To migrate other route types, add a listener with the matching protocol to the replacement Gateway.
The route controllers are enabled by default.
Don't disable them in the `controllers` list of the `GatewayConfiguration`.
For more information, see [Gateway API controllers](/operator/reference/control-plane-feature-gates-and-controllers/#gateway-api-controllers).

A `GRPCRoute` attached to an `HTTP` listener needs `http2` in the `KONG_PROXY_LISTEN` environment variable of the gateway container.

{{ site.operator_product_name_short }} reads `TLSRoute` resources through the Gateway API `v1` version.
Before you migrate `TLSRoute` resources, check that the `TLSRoute` CRD in your cluster serves `v1`:

```bash
kubectl get crd tlsroutes.gateway.networking.k8s.io -o jsonpath='{.spec.versions[*].name}'
```

If the output doesn't include `v1`, upgrade your Gateway API CRDs.

## Before you begin

{% include /operator/kic-migration/before-you-begin.md %}

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

This guide names the new resources `kong-migrated`.
If that name is already in use, choose another name and use it throughout this guide.

The route examples assume that the routes and both Gateways are in `$NAMESPACE`.
If your routes are in other namespaces, set the namespace in the parent reference, and configure the replacement listener to allow routes from those namespaces.
If you use GitOps, update the route manifests so that reconciliation doesn't revert the migration changes.

## Preserve the existing Service

{% include /operator/kic-migration/preserve-service.md %}

## Install {{ site.operator_product_name }}

{% include /operator/kic-migration/install-operator.md %}

## Create the replacement gateway

The replacement gateway uses its own Gateway and GatewayClass.
Keep the existing Gateway, GatewayClass, and routing resources in place until cleanup.

Create a `GatewayConfiguration`, a `GatewayClass`, and a `Gateway` that use your current image and replica count.
The new Service is internal (`ClusterIP`), so it doesn't change client traffic:

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

When the Gateway is programmed, you can attach routes to it.

## Attach routes to both Gateways

A route attaches to a Gateway through its `spec.parentRefs` list.
Add the replacement Gateway as another parent so that both installations serve the same route during validation.

For example, add `kong-migrated` to the parent references of an `HTTPRoute` named `example-route`:

```bash
kubectl patch httproute example-route -n "${NAMESPACE}" --type json \
  -p '[{"op":"add","path":"/spec/parentRefs/-","value":{"kind":"Gateway","name":"kong-migrated"}}]'
```

For other route types, replace `httproute` with the route kind, for example `grpcroute` or `tlsroute`.

The patch keeps the existing parent references.
The route must already have a `parentRefs` list.
Before you apply or retry the patch, check that `kong-migrated` isn't already in the list.
If the old parent reference uses `sectionName` or `port`, add the matching listener restriction to the new reference too.

Repeat the patch for every route attached to the old Gateway that you want to migrate.
Before you validate the replacement, check that each route references both Gateways.
Keep the old parent references until cleanup.

## Validate the replacement

{% include /operator/kic-migration/validate.md %}

## Switch traffic

{% include /operator/kic-migration/switch-traffic.md %}

### Roll back

{% include /operator/kic-migration/roll-back.md %}

## Retire the old installation

Before you start cleanup, wait until:

* Application checks pass through the existing address.
* Old connections have drained.
* Load balancer target changes have converged.

You can run cleanup later, in a maintenance window.
Repeat your application checks after each operation.

{:.warning}
> Cleanup ends the simple rollback path. Verify traffic after each operation, and wait for routing to settle before you continue. Avoid {{ site.operator_product_name }} restarts during cleanup.

1. Remove the old Gateway parent reference from each migrated route.
   For example, edit `example-route`:

   ```bash
   kubectl edit httproute example-route -n "${NAMESPACE}"
   ```

   In `spec.parentRefs`, remove only the entries that reference the old Gateway.
   Keep `kong-migrated` and any unrelated parents.
   Repeat for the remaining routes, and verify application traffic before you continue.

1. Check that no routes still depend on the old Gateway, including any routes added during migration.
   Then delete the old Gateway:

   ```bash
   kubectl delete gateway -n "${NAMESPACE}" ${OLD_GATEWAY}
   ```

   Verify application traffic before you continue.

1. If no other Gateways use the old GatewayClass, delete it:

   ```bash
   kubectl delete gatewayclass ${OLD_GATEWAY_CLASS}
   ```

   Verify application traffic before you continue.

1. Uninstall the Helm release:

   ```bash
   helm uninstall -n ${NAMESPACE} ${RELEASE_NAME}
   ```

   Helm reports the proxy Service as kept.

The migration is complete.
Keep the retained Service in your managed manifests.
{{ site.operator_product_name_short }} publishes the address of its own internal Service in resource status.
If your tooling reads that field, account for the different address.

## Troubleshooting

{% table %}
columns:
  - title: Symptom
    key: symptom
  - title: Cause
    key: cause
  - title: Resolution
    key: resolution
rows:
  - symptom: The Service has no endpoints after the cutover.
    cause: The selector was applied with `--type merge`, which combined the old and new selectors.
    resolution: Apply the selector again with `--type json` and a `replace` operation.
  - symptom: A second Gateway that uses the same `GatewayClass` never becomes programmed, and its ingress Service stays `<pending>`.
    cause: The shared `GatewayConfiguration` pins a specific load balancer address, and you can't assign one address to two Services.
    resolution: If you pin addresses, give each Gateway its own `GatewayConfiguration`.
  - symptom: Requests return `404` for a few seconds during cleanup.
    cause: Several Gateway API objects changed while {{ site.operator_product_name_short }} was restarting, so the control plane pushed a configuration that was missing routes.
    resolution: Verify traffic after each step, and increase `cache.initSyncDuration`.
  - symptom: Patching an `HTTPRoute` fails with `context deadline exceeded` when calling `gwapi.validations.kong.konghq.com`.
    cause: "{{ site.operator_product_name_short }}'s validating webhook wasn't ready yet."
    resolution: Retry the patch.
{% endtable %}

## Optional: Transfer address management

{% include /operator/kic-migration/transfer-address.md %}
