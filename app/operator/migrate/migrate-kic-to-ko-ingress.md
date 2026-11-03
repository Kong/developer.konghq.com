---
title: "Migrate an Ingress configuration to {{ site.operator_product_name }}"
description: "Migrate Ingress routing from {{ site.kic_product_name }} to {{ site.operator_product_name }} while preserving your existing Service and client address."
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
  - text: "Migrate a Gateway API configuration"
    url: /operator/migrate/migrate-kic-to-ko-gateway-api/
  - text: "Version compatibility"
    url: /operator/reference/version-compatibility/
  - text: "GatewayConfiguration reference"
    url: /operator/reference/custom-resources/#gatewayconfiguration
---

Migrate your existing `Ingress` resources from {{ site.kic_product_name }} to {{ site.operator_product_name }} while you keep the Service and address your clients use.
During the migration, both controllers read the same Ingress resources.
You don't need to convert your Ingress resources to Gateway API routes.

When you finish this guide, a {{ site.operator_product_name }}-managed gateway serves traffic behind your retained Service.
You continue to manage that Service yourself.
If you use both Ingress and Gateway API resources, start with the [migration overview](/operator/migrate/migrate-kic-to-ko/#if-you-use-both-apis).

## Before you begin

{% include /operator/kic-migration/before-you-begin.md %}
Set `INGRESS_CLASS` to the class that your existing Ingress resources use.

```bash
export NAMESPACE=default
export RELEASE_NAME=kong
export KIC_CHART_VERSION='<installed-chart-version>'
export PROXY_SERVICE=kong-proxy
export GATEWAY_IMAGE='<current-image:tag>'
export GATEWAY_REPLICAS=2
export INGRESS_CLASS=kong
```

This guide names the new resources `kong-migrated`.
If that name is already in use, choose another name and use it throughout this guide.

## Preserve the existing Service

{% include /operator/kic-migration/preserve-service.md %}

## Install {{ site.operator_product_name }}

{% include /operator/kic-migration/install-operator.md %}

## Create the replacement gateway

{{ site.operator_product_name_short }} uses a `Gateway` resource to manage the replacement deployment, even though your application routing still uses Ingress resources.
To make the replacement process those Ingress resources, set `controlPlaneOptions.ingressClass` to your existing ingress class.

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
    ingressClass: ${INGRESS_CLASS}
    cache:
      initSyncDuration: 30s
    controllers:
    - name: INGRESS_NETWORKINGV1
      state: enabled
    - name: INGRESS_CLASS_NETWORKINGV1
      state: enabled
    - name: KONG_PLUGIN
      state: enabled
    - name: KONG_CLUSTERPLUGIN
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

Both installations now translate the same Ingress resources for their own data planes.
You don't need to attach routes.

## Validate the replacement

{% include /operator/kic-migration/validate.md %}

## Switch traffic

{% include /operator/kic-migration/switch-traffic.md aws_link=true %}

### Roll back

{% include /operator/kic-migration/roll-back.md %}

## Retire the old installation

Before you start cleanup, wait until:

* Application checks pass through the existing address.
* Old connections have drained.
* Load balancer target changes have converged.

You can run cleanup later, in a maintenance window.

{:.warning}
> Cleanup ends the simple rollback path. Verify traffic after the uninstall, and wait for routing to settle. Avoid {{ site.operator_product_name }} restarts during cleanup.

1. Uninstall the Helm release:

   ```bash
   helm uninstall -n ${NAMESPACE} ${RELEASE_NAME}
   ```

   Helm reports the proxy Service as kept.

1. Verify that traffic through your address is still healthy.

The uninstall also removes the old `IngressClass` object.
If other tooling depends on it, see [IngressClass after uninstall](#ingressclass-after-uninstall).

The migration is complete.
Keep the retained Service in your managed manifests.
{{ site.operator_product_name_short }} publishes the address of its own internal Service in resource status.
If your tooling reads that field, see [Published addresses](#published-addresses).

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
  - symptom: The new Gateway is programmed, but it returns `404` for every Ingress resource.
    cause: "`controlPlaneOptions.ingressClass` doesn't match the class that your Ingress resources reference. When `ingressClass` isn't set, the control plane uses the `kong` class."
    resolution: Set `ingressClass` in the `GatewayConfiguration` to the class that your Ingress resources use.
  - symptom: The Service has no endpoints after the cutover.
    cause: The selector was applied with `--type merge`, which combined the old and new selectors.
    resolution: Apply the selector again with `--type json` and a `replace` operation.
  - symptom: A second Gateway that uses the same `GatewayClass` never becomes programmed, and its ingress Service stays `<pending>`.
    cause: The shared `GatewayConfiguration` pins a specific load balancer address, and you can't assign one address to two Services.
    resolution: If you pin addresses, give each Gateway its own `GatewayConfiguration`.
  - symptom: Requests return `404` for a few seconds during cleanup.
    cause: Several Gateway API objects changed while {{ site.operator_product_name_short }} was restarting, so the control plane pushed a configuration that was missing routes.
    resolution: Verify traffic after each step, and increase `cache.initSyncDuration`.
  - symptom: Ingress `status.loadBalancer` shows a cluster IP after the migration.
    cause: "{{ site.operator_product_name_short }} publishes the address of its own data plane ingress Service, which is `ClusterIP` in this guide."
    resolution: "This is expected. See [Optional: Transfer address management](#optional-transfer-address-management)."
{% endtable %}

## Additional details

### Published addresses

{{ site.operator_product_name_short }} publishes the `ClusterIP` of its own data plane Service.
This address is different from the address on your retained Service.
Account for this difference in tooling that reads resource status.

While both controllers run, the published Ingress `status.loadBalancer` address can switch between the two installations.
Validate application traffic through the retained Service.

### GatewayConfiguration settings

The example sets `cache.initSyncDuration` to `30s`.
This gives the control plane more time to initialize its Kubernetes caches before the first configuration push.
The default value is `5s`.
For other settings, see the [`GatewayConfiguration` reference](/operator/reference/custom-resources/#gatewayconfiguration).

### AWS load balancer cutover

On AWS with `aws-load-balancer-nlb-target-type: ip`, the load balancer registers pod IPs directly instead of node ports.
In this case, the selector change is a target group membership change.
New targets must pass health checks while old targets drain, so the cutover is gradual.
The old pods keep serving traffic while they're removed from the target group, so the cutover doesn't cause an outage.
Wait for the target group to fully converge before you start cleanup.

With the default `instance` target type, the selector change doesn't affect the load balancer.

### Stop the old controller before uninstall

To stop {{ site.kic_product_name_short }} from reconciling before the uninstall, you can scale its controller down to zero replicas.
You can only do this with the `ingress` chart, which runs the controller in its own Deployment:

```bash
kubectl scale deploy -n ${NAMESPACE} ${RELEASE_NAME}-controller --replicas=0
```

The `kong` chart runs the controller as a container in the same Deployment as the gateway, so you can't scale it separately.
Uninstall the release instead.

### IngressClass after uninstall

The Helm uninstall also removes the `IngressClass` object.
This doesn't affect routing.
{{ site.operator_product_name_short }} matches Ingress resources on the `spec.ingressClassName` string, and only reads the `IngressClass` object to resolve the default class annotation.
Recreate the `IngressClass` only if other tooling depends on it.

## Optional: Transfer address management

{% include /operator/kic-migration/transfer-address.md %}
