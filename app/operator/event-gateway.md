---
title: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
description: "Deploy and validate {{ site.event_gateway }} resources with {{ site.operator_product_name }}"
content_type: reference
layout: reference
permalink: /operator/event-gateway/
products:
  - operator
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts

min_version:
  operator: '2.2'

related_resources:
  - text: Deploy {{ site.event_gateway }} with port mapping
    url: /operator/get-started/event-gateway/port-mapping/
  - text: Deploy {{ site.event_gateway }} with TLSRoute and SNI
    url: /operator/get-started/event-gateway/tlsroute-sni/
  - text: Validate Kafka message schemas with EventGatewaySchemaRegistry
    url: /operator/dataplanes/how-to/event-gateway-schema-registry/
  - text: "{{ site.event_gateway }} architecture"
    url: /event-gateway/architecture/
  - text: Backend clusters
    url: /event-gateway/entities/backend-cluster/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Listeners
    url: /event-gateway/entities/listener/
  - text: Policies
    url: /event-gateway/entities/policy/
  - text: Gateway API
    url: /operator/dataplanes/gateway-api/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/

---

{{ site.operator_product_name }} reconciles {{ site.event_gateway }} resources and deploys a matching `KegDataPlane` workload in your Kubernetes cluster.

For a step-by-step walkthrough you can apply directly to a cluster, see the [{{ site.event_gateway }} getting started guide](/operator/get-started/event-gateway/install/).

The operator manages three layers:

- A control plane: either a `KonnectEventGateway` in `konnect.konghq.com/v1alpha1`, which creates the control plane in {{ site.konnect_short_name }}, or an [`OnPremEventGateway` in Tech Preview](#on-prem-control-plane) in `eventgateway.konghq.com/v1alpha1`, served by a gw-admin control plane in your cluster
- {{ site.event_gateway_short }} configuration resources in `configuration.konghq.com/v1alpha1`
- A `KegDataPlane` workload in `eventgateway.konghq.com/v1alpha1`

## Resource model

Here are the Kubernetes resources that form a typical {{ site.event_gateway }} deployment:

<!--vale off-->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: API group
    key: api_group
  - title: Purpose
    key: purpose
rows:
  - resource: "`KonnectEventGateway`"
    api_group: "`konnect.konghq.com/v1alpha1`"
    purpose: Creates the {{ site.event_gateway_short }} control plane in {{ site.konnect_short_name }}
  - resource: "`OnPremEventGateway` (Tech Preview)"
    api_group: "`eventgateway.konghq.com/v1alpha1`"
    purpose: Defines an on-prem {{ site.event_gateway_short }} control plane, whose configuration {{ site.operator_product_name }} pushes to gw-admin
  - resource: "`GWAdmin` (Tech Preview)"
    api_group: "`gateway-operator.konghq.com/v1alpha1`"
    purpose: Deploys gw-admin, the in-cluster control plane that serves `OnPremEventGateway` configuration to data planes
  - resource: "`EventGatewayBackendCluster`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Describes the upstream Kafka cluster
  - resource: "`EventGatewayVirtualCluster`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Defines the virtual cluster presented to clients
  - resource: "`EventGatewayListener`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Declares listener addresses and ports
  - resource: "`EventGatewayListenerPolicy`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Configures routing and TLS behavior on the listener
  - resource: "`EventGatewayVirtualClusterConsumePolicy`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Applies consume-side policy to a virtual cluster
  - resource: "`EventGatewayVirtualClusterProducePolicy`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Applies produce-side policy to a virtual cluster
  - resource: "`EventGatewaySchemaRegistry`"
    api_group: "`configuration.konghq.com/v1alpha1`"
    purpose: Connects to a schema registry for consume and produce schema validation policies
  - resource: "`KegDataPlane`"
    api_group: "`eventgateway.konghq.com/v1alpha1`"
    purpose: Deploys the {{ site.event_gateway_short }} data plane in Kubernetes
{% endtable %}
<!--vale on-->

Resources reference each other in this order:

1. `EventGatewayBackendCluster.spec.parentRef` (or the deprecated `spec.gatewayRef`) points to a `KonnectEventGateway`
2. `EventGatewayVirtualCluster.spec.eventGatewayBackendClusterRef` points to an `EventGatewayBackendCluster`
3. `EventGatewayListener.spec.parentRef` (or the deprecated `spec.gatewayRef`) points to the same `KonnectEventGateway`
4. `EventGatewayListenerPolicy.spec.eventGatewayListenerRef` points to an `EventGatewayListener`
5. Consume and produce policies point to an `EventGatewayVirtualCluster`
6. `EventGatewaySchemaRegistry.spec.parentRef` (or the deprecated `spec.gatewayRef`) points to the same `KonnectEventGateway`, and consume or produce policies reference it via `schemaValidation.config.confluentSchemaRegistry.schemaRegistry`
7. `KegDataPlane.spec.controlPlaneRef` points to the `KonnectEventGateway`

With an on-prem control plane, the same resources point to an `OnPremEventGateway` instead, with `spec.parentRef`, and `KegDataPlane.spec.controlPlaneRef` uses `type: onpremNamespacedRef`. See [On-prem control plane](#on-prem-control-plane).

{:.info}
> Starting with {{ site.operator_product_name }} 2.4, a reference from one {{ site.event_gateway_short }} entity to another names the Kubernetes object, as `{kind, name, namespace}`, with `kind` and `namespace` optional. For example, a listener policy's `forwardToVirtualCluster` `destination.name` is the name of the `EventGatewayVirtualCluster` resource, not its `apiSpec.name`. The same applies to the `schemaRegistry` of schema validation and transcode policies, the static `key` of encrypt policies, and the `tlsTrustBundles` of TLS server policies.

## Deployment patterns

There are two ways to expose {{ site.event_gateway }} with the operator:
* [`LoadBalancer` with `portMapping`](#loadbalancer-with-portmapping). Use this pattern if:
  * you need a fast local validation loop
  * you can expose one port per broker
  * a stable external IP is acceptable for clients
* [`Gateway` with `TLSRoute` and SNI](#gateway-with-tlsroute-and-sni). Use this pattern if:
  * you want a production-oriented edge pattern
  * you need a single public Kafka listener
  * you want broker metadata returned as DNS names on one port
  * you plan to front multiple virtual clusters behind one entrypoint


### `LoadBalancer` with `portMapping`

This pattern suits local validation and simple deployments where exposing one port per broker is acceptable. The `KegDataPlane` exposes a `LoadBalancer` Service with one port for bootstrap traffic and one port per broker.

The listener policy uses `forwardToVirtualCluster.config.type: portMapping`:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayListenerPolicy
metadata:
  name: example-listener-policy
  namespace: kong
spec:
  apiSpec:
    type: forwardToVirtualCluster
    forwardToVirtualCluster:
      name: forward
      config:
        type: portMapping
        portMapping:
          advertisedHost: "10.0.1.1"
          bootstrapPort: at_start
          destination:
            name: example-virtual-cluster
  eventGatewayListenerRef:
    type: namespacedRef
    namespacedRef:
      name: example-listener
```

{:.info}
> Set `advertisedHost` explicitly. Kafka clients use it when resolving broker metadata after bootstrap.

In a three-broker cluster, the data plane Service exposes:

- `9092` for bootstrap
- `9093` for broker 0
- `9094` for broker 1
- `9095` for broker 2

For a full deployment walkthrough, see [Deploy {{ site.event_gateway }} with port mapping](/operator/get-started/event-gateway/port-mapping/).

### `Gateway` with `TLSRoute` and SNI

This is the production-oriented pattern. A single TLS listener at the Kubernetes edge routes Kafka traffic to the correct virtual cluster by SNI:

- A Kubernetes `Gateway` exposes a single TLS listener
- A `TLSRoute` forwards encrypted traffic to the `KegDataPlane` Service
- An `EventGatewayListenerPolicy` with `type: tlsServer` terminates TLS in {{ site.event_gateway }}
- A second `EventGatewayListenerPolicy` with `forwardToVirtualCluster.config.type: sni` routes clients by SNI

This keeps the public edge to a single port and returns broker metadata as stable DNS names instead of distinct ports.

The SNI forwarding policy looks like this:

```yaml
apiVersion: configuration.konghq.com/v1alpha1
kind: EventGatewayListenerPolicy
metadata:
  name: sni-forward
  namespace: kong
spec:
  apiSpec:
    type: forwardToVirtualCluster
    forwardToVirtualCluster:
      name: forward_sni
      config:
        type: sni
        sni:
          sniSuffix: ".keg.example.com"
          brokerHostFormat:
            type: per_cluster_suffix
          advertisedPort: 9092
  eventGatewayListenerRef:
    type: namespacedRef
    namespacedRef:
      name: sni-listener
```

With a virtual cluster `dnsLabel` of `vc-tls-1`, clients receive metadata like:

- `bootstrap.vc-tls-1.keg.example.com:9092`
- `broker-0.vc-tls-1.keg.example.com:9092`
- `broker-1.vc-tls-1.keg.example.com:9092`
- `broker-2.vc-tls-1.keg.example.com:9092`

{:.info}
> In production, configure wildcard DNS so that the advertised bootstrap and broker hostnames resolve to the `Gateway` address.

For a full deployment walkthrough, see [Deploy {{ site.event_gateway }} with TLSRoute and SNI](/operator/get-started/event-gateway/tlsroute-sni/).



## On-prem control plane

{% include operator/event-gateway-on-prem-tech-preview.md %}

An `OnPremEventGateway` replaces the {{ site.konnect_short_name }}-hosted control plane with gw-admin, a control plane that runs in your cluster. Three resources work together:

- A `GWAdmin` deploys gw-admin: a Deployment, and the Services that {{site.operator_product_name}} and the data planes connect to. {{site.operator_product_name}} creates the certificate authorities that gw-admin, {{site.operator_product_name}}, and the data planes use to authenticate each other, and renews the certificates before they expire.
- An `OnPremEventGateway` references a `GWAdmin` with `spec.gwAdminRef`. It doesn't create any Pods. {{site.operator_product_name}} collects the {{ site.event_gateway_short }} resources attached to it and pushes their configuration to every gw-admin Pod over mTLS.
- A `KegDataPlane` references the `OnPremEventGateway` with `spec.controlPlaneRef.type: onpremNamespacedRef`. {{site.operator_product_name}} issues it a client certificate, registers the certificate on gw-admin, and the data plane pulls its configuration from gw-admin.

Nothing is sent to {{ site.konnect_short_name }}, so {{ site.konnect_short_name }} features such as analytics and the {{ site.konnect_short_name }} UI aren't available. To follow the getting started series with an on-prem control plane, see [Install {{site.operator_product_name}} for {{ site.event_gateway }}](/operator/get-started/event-gateway/install/).

### Enable the on-prem controllers

The `GWAdmin` and `OnPremEventGateway` controllers are disabled by default. Enable them alongside the `KegDataPlane` controller when installing {{site.operator_product_name}}:

```bash
--set env.ENABLE_CONTROLLER_KEGDATAPLANE=true \
--set env.ENABLE_CONTROLLER_GWADMIN=true \
--set env.ENABLE_CONTROLLER_ONPREMEVENTGATEWAY=true
```

### License

gw-admin requires an {{ site.event_gateway_short }} license with the `event_gateway` entitlement. This is a signed license token, not the JSON license that `KongLicense` uses for {{ site.base_gateway }}. Store it in a Secret labeled `konghq.com/secret=true`, and reference the Secret key from the `GWAdmin`:

```yaml
apiVersion: gateway-operator.konghq.com/v1alpha1
kind: GWAdmin
metadata:
  name: gw-admin
  namespace: kong
spec:
  license:
    secretRef:
      name: gw-admin-license
      key: license
```

{{site.operator_product_name}} mounts the license in the gw-admin Pods. gw-admin, not {{site.operator_product_name}}, validates it, and doesn't start without a valid license. To renew the license, update the Secret in place: gw-admin reads the mounted file again on its periodic license checks, without a restart. The `KegDataPlane` doesn't need a `KongLicense`.

### Reference an OnPremEventGateway

`EventGatewayBackendCluster`, `EventGatewayListener`, `EventGatewaySchemaRegistry`, `EventGatewayStaticKey`, `EventGatewayTLSTrustBundle`, and `EventGatewayDataPlaneCertificate` attach to an `OnPremEventGateway` with `spec.parentRef`, which must set `group` and `kind`:

```yaml
spec:
  parentRef:
    group: eventgateway.konghq.com
    kind: OnPremEventGateway
    name: cp-event-1
```

Virtual clusters and policies attach to their parent entities as they do with {{ site.konnect_short_name }}, so they don't change.

You can't change the kind of the referenced gateway on an existing resource to move it between a `KonnectEventGateway` and an `OnPremEventGateway`. Delete and recreate it instead.

A `KegDataPlane` attaches to an `OnPremEventGateway` with `spec.controlPlaneRef.type: onpremNamespacedRef`:

```yaml
spec:
  controlPlaneRef:
    type: onpremNamespacedRef
    onpremNamespacedRef:
      name: cp-event-1
```

The control plane reference can't be changed after the `KegDataPlane` is created. The name of an on-prem `KegDataPlane` must be a valid DNS label of at most 57 characters.

To reference a `GWAdmin` or an `OnPremEventGateway` in another namespace, create a `KongReferenceGrant` in the namespace of the referenced resource. See [Cross namespace references](/operator/konnect/cross-namespace-references/).

### How configuration is pushed

{{site.operator_product_name}} pushes the whole configuration of an `OnPremEventGateway` as one unit. If any entity can't be sent, for example a policy that references a resource that doesn't exist, {{site.operator_product_name}} doesn't push the configuration at all, and gw-admin keeps serving the last configuration that it accepted. The `OnPremEventGateway` reports `Programmed=False` with the reason `InvalidEntities` and names the entities, and each entity reports why in its own `Programmed` condition. Fix or delete the entity to resume pushing.

`status.configRevision` on the `OnPremEventGateway` increases by one every time its configuration changes.

### Status conditions

<!--vale off-->
{% table %}
columns:
  - title: Resource
    key: resource
  - title: Condition
    key: condition
  - title: Meaning
    key: meaning
rows:
  - resource: "`GWAdmin`"
    condition: "`Ready`"
    meaning: The certificates and the gw-admin Deployment are configured. It can be `True` before the gw-admin Pod is running, so wait for the `gw-admin` Deployment to be available too.
  - resource: "`GWAdmin`"
    condition: "`LicenseProvisioned`"
    meaning: The license Secret and key exist and are mounted in the gw-admin Pods. It doesn't mean the license is valid.
  - resource: "`OnPremEventGateway`"
    condition: "`GWAdminResolved`"
    meaning: "The `GWAdmin` can serve the gateway. The reason is `NotFound` if the `GWAdmin` doesn't exist, `RefNotPermitted` if a cross-namespace reference has no `KongReferenceGrant`, and `NotReady` while gw-admin has no running Pod."
  - resource: "`OnPremEventGateway`"
    condition: "`ConfigurationPushed`"
    meaning: The current configuration reached every gw-admin Pod.
  - resource: "`OnPremEventGateway`"
    condition: "`Programmed`"
    meaning: The configuration was applied. Wait on this condition, as you would for a `KonnectEventGateway`.
  - resource: "`KegDataPlane`"
    condition: "`OnPremEventGatewayResolved`"
    meaning: The `OnPremEventGateway`, and what the data plane needs from its `GWAdmin`, were found.
  - resource: "`KegDataPlane`"
    condition: "`GWAdminCertificateRegistered`"
    meaning: The client certificate of the data plane is registered on gw-admin.
{% endtable %}
<!--vale on-->

{{ site.event_gateway_short }} configuration resources report a `Programmed` condition, as they do with {{site.konnect_short_name}}. With an on-prem control plane, `Programmed=True` means the resource is in the configuration pushed to gw-admin.

### Troubleshooting

#### A listener policy isn't programmed

If the `Programmed` message of a `forwardToVirtualCluster` listener policy reports that an `EventGatewayVirtualCluster` is not found, check `destination.name`. It must be the name of the `EventGatewayVirtualCluster` resource, not its `apiSpec.name`. Until you fix it, no configuration change is pushed for the whole `OnPremEventGateway`.

#### The gw-admin Pod doesn't start

Check the gw-admin logs:

```bash
kubectl logs -n kong deployment/gw-admin
```

gw-admin doesn't start without a valid {{ site.event_gateway_short }} license. Make sure that the Secret holds the license token with the `event_gateway` entitlement, not a {{ site.ee_product_name }} JSON license.
