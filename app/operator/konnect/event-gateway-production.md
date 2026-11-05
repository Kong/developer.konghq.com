---
title: "Run {{ site.event_gateway }} in production with {{ site.operator_product_name }}"
description: "Recommended architecture for running {{ site.event_gateway }} data planes on Kubernetes with {{ site.operator_product_name }}: topology, placement, scaling, TLS, DNS, upgrades, and GitOps."
content_type: reference
layout: reference
products:
  - operator
  - event-gateway
breadcrumbs:
  - /operator/
  - index: operator
    group: Konnect
  - index: operator
    group: Konnect
    section: Key Concepts

# TODO: Confirm the minimum version. HPA reconciliation for KegDataPlane landed in 2.3.0, and the drain-aware termination grace period landed in 2.4.0-rapid.3.1.
min_version:
  operator: '2.3'

related_resources:
  - text: "{{ site.event_gateway }} with {{ site.operator_product_name }}"
    url: /operator/konnect/event-gateway/
  - text: Deploy {{ site.event_gateway }} with TLSRoute and SNI
    url: /operator/get-started/event-gateway/tlsroute-sni/
  - text: "{{ site.event_gateway }} architecture"
    url: /event-gateway/architecture/
  - text: Virtual clusters
    url: /event-gateway/entities/virtual-cluster/
  - text: Configure observability with OpenTelemetry
    url: /event-gateway/configure-observability-with-otel/
  - text: "{{ site.event_gateway_short }} metrics reference"
    url: /event-gateway/metrics/
  - text: Cross namespace references
    url: /operator/konnect/cross-namespace-references/
---

{{ site.operator_product_name }} is the recommended way to run {{ site.event_gateway }} on Kubernetes. The operator creates the {{ site.event_gateway_short }} control plane in {{ site.konnect_short_name }}, reconciles backend clusters, virtual clusters, listeners, and policies from Kubernetes resources, and deploys the data plane as a `KegDataPlane` workload.

This page describes the recommended production architecture and the `KegDataPlane` settings that implement it. It assumes you've already deployed {{ site.event_gateway_short }} with the operator at least once. If you haven't, start with the [{{ site.event_gateway }} getting started guide](/operator/get-started/event-gateway/install/), then read [{{ site.event_gateway }} with {{ site.operator_product_name }}](/operator/konnect/event-gateway/) for the resource model.

## Prerequisites

This architecture assumes that:

* You run a production Kubernetes cluster, for example EKS, GKE, AKS, or a self-managed distribution.
* Your backend Kafka clusters are already provisioned and reachable from the Kubernetes cluster. Sizing and operating the Kafka brokers is out of scope for this page.
* You have a {{ site.konnect_short_name }} account, and the cluster allows egress to {{ site.konnect_short_name }} so the operator can manage the control plane and the data plane can poll it for configuration.

## Recommended topology

In production, expose {{ site.event_gateway_short }} through a Kubernetes `Gateway` with a single TLS listener and a `TLSRoute`, and route virtual clusters by SNI. Kafka clients connect only to the `Gateway`. Backend brokers are never exposed to clients directly.

<!--vale off-->
{% mermaid %}
flowchart LR

Client["Kafka clients<br/>(producers and consumers)"]

subgraph K8s ["Kubernetes cluster"]
  direction LR
  GW["Kubernetes Gateway<br/>TLS listener, passthrough"]
  Route["TLSRoute<br/>*.vc.keg.example.com"]
  subgraph KEG ["KegDataPlane (replicas across zones)"]
    P1["keg pod<br/>zone a"]
    P2["keg pod<br/>zone b"]
    P3["keg pod<br/>zone c"]
  end
end

Kafka["Backend Kafka cluster"]
Konnect["{{ site.konnect_short_name }}<br/>{{ site.event_gateway_short }} control plane"]

Client -- "TLS + SNI" --> GW --> Route --> KEG
KEG --> Kafka
KEG -. "polls config" .-> Konnect
{% endmermaid %}
<!--vale on-->

This topology has the following properties:

* **TLS passes through the `Gateway`.** {{ site.event_gateway_short }} terminates TLS with a `tlsServer` listener policy, so it can read the SNI hostname and route the connection to the right virtual cluster. Don't terminate TLS at the `Gateway` or at a cloud load balancer in front of it.
* **One public port for every virtual cluster.** The `forwardToVirtualCluster` listener policy with `type: sni` advertises brokers as DNS names on a single port, so adding a virtual cluster or a broker doesn't require opening new ports.
* **The data plane stays internal.** The `KegDataPlane` Kafka Service is a `ClusterIP` Service, named `<kegdataplane-name>-kafka`, that only the `TLSRoute` targets.
* **Load balancing happens at Layer 4.** Kafka uses its own TCP protocol, so any load balancer in the path must be a network (TCP) load balancer. HTTP or application load balancers that inspect or rewrite traffic don't work.

The `LoadBalancer` with `portMapping` pattern is suitable for development and validation only. It needs one port per broker for each virtual cluster, which doesn't scale as brokers are added. For both patterns, see [Deployment patterns](/operator/konnect/event-gateway/#deployment-patterns).

## Namespaces

Separate components into namespaces so you can apply RBAC and network policies to each one independently. A common layout looks like this:

{% table %}
columns:
  - title: Namespace
    key: namespace
  - title: Contents
    key: contents
rows:
  - namespace: "`kong-system`"
    contents: "{{ site.operator_product_name }}"
  - namespace: "`kong`"
    contents: |
      `KonnectEventGateway`, {{ site.event_gateway_short }} configuration resources, `KegDataPlane`, `Gateway`, and `TLSRoute`
  - namespace: "`kafka`"
    contents: Backend Kafka cluster, if it runs in the same Kubernetes cluster
  - namespace: "`observability`"
    contents: OpenTelemetry Collector, Prometheus, and log shipping
{% endtable %}

`KegDataPlane.spec.controlPlaneRef` must reference a `KonnectEventGateway` in the same namespace. To reference resources across namespaces elsewhere, see [cross namespace references](/operator/konnect/cross-namespace-references/).

## Configure the data plane for production

You configure the data plane Deployment through `KegDataPlane.spec.deployment`. The `podTemplateSpec` field is applied on top of the Deployment that the operator generates using a strategic merge patch, so you only need to set the fields you want to change. The {{ site.event_gateway_short }} container is named `keg`.

The following example combines all the recommendations in this section:

```yaml
apiVersion: eventgateway.konghq.com/v1alpha1
kind: KegDataPlane
metadata:
  name: keg-prod
  namespace: kong
spec:
  controlPlaneRef:
    type: konnectNamespacedRef
    konnectNamespacedRef:
      name: cp-event-prod
  network:
    services:
      kafka:
        type: ClusterIP
        ports:
          - name: kafka
            port: 9092
            targetPort: 9092
  config:
    runtime:
      drainDurationSeconds: 30
      shutdownTimeoutSeconds: 30
    observability:
      logFlags: info
  deployment:
    scaling:
      horizontal:
        minReplicas: 3
        maxReplicas: 12
        metrics:
          - type: Resource
            resource:
              name: cpu
              target:
                type: Utilization
                averageUtilization: 70
    podTemplateSpec:
      metadata:
        labels:
          app.kubernetes.io/name: keg-prod
      spec:
        nodeSelector:
          workload: event-gateway
        tolerations:
          - key: workload
            operator: Equal
            value: event-gateway
            effect: NoSchedule
        topologySpreadConstraints:
          - maxSkew: 1
            topologyKey: topology.kubernetes.io/zone
            whenUnsatisfiable: DoNotSchedule
            labelSelector:
              matchLabels:
                app.kubernetes.io/name: keg-prod
        containers:
          - name: keg
            resources:
              requests:
                cpu: "2"
                memory: 2Gi
              limits:
                cpu: "2"
                memory: 2Gi
```

<!-- TODO: Get recommended starting values from engineering for CPU, memory, HPA metrics and targets, and drain and shutdown durations. The values in the example are placeholders. -->

The values in this example illustrate the shape of the configuration. Size them for your own traffic.

### Workload placement

Run {{ site.event_gateway_short }} pods on a dedicated node pool so that other workloads can't compete with them for network and CPU:

* Taint the dedicated nodes, and add a matching `tolerations` entry and a `nodeSelector` to `podTemplateSpec` so that only {{ site.event_gateway_short }} pods are scheduled there.
* Add a `topologySpreadConstraints` entry with `topologyKey: topology.kubernetes.io/zone` to spread replicas across availability zones. Set a pod label in `podTemplateSpec.metadata.labels` and select on it in the constraint's `labelSelector`.

You can use `podAntiAffinity` on the same zone topology key instead of topology spread constraints if your cluster policies require it.

### Resources

{{ site.event_gateway_short }} handles a large number of concurrent TCP connections and significant network I/O. Set CPU and memory requests equal to limits on the `keg` container. This gives the pods the Guaranteed QoS class, so they get predictable CPU and are the last pods that Kubernetes evicts when a node runs short of resources.

### Scaling

The {{ site.event_gateway_short }} data plane is stateless: it stores no data and needs no persistent volumes. To handle more traffic or more client connections, add replicas.

Use `spec.deployment.scaling.horizontal` instead of a fixed `replicas` count. The operator creates a `HorizontalPodAutoscaler` from this configuration, keeps it up to date, and deletes it if you remove the configuration. The `replicas` and `scaling` fields are mutually exclusive.

Set `minReplicas` to at least the number of availability zones you spread across, so that one replica runs in each zone.

<!-- TODO: Confirm the recommended scaling metrics with engineering (CPU only, or CPU plus a connection-count or throughput metric through a custom metrics adapter). -->

### Graceful shutdown and rolling updates

When a pod shuts down, {{ site.event_gateway_short }} drains existing connections before it exits. You control this with `spec.config.runtime.drainDurationSeconds` and `spec.config.runtime.shutdownTimeoutSeconds`. If you don't set them, {{ site.event_gateway_short }} uses its defaults of 5 seconds and 10 seconds.

The operator raises the pod's termination grace period to cover the drain, the shutdown timeout, and a 5 second margin, unless you set `terminationGracePeriodSeconds` in `podTemplateSpec` yourself. Because the data plane is stateless, a standard rolling update replaces pods without interrupting the platform. Kafka clients reconnect to the remaining pods.

### Data plane configuration

Set data plane runtime options with the typed fields in `spec.config`, such as `observability.logFlags`, `observability.logFormat`, and `configPollIntervalSeconds`. Each field maps to a `KEG__` configuration parameter. For the full list of parameters, see the [{{ site.event_gateway_short }} configuration reference](/event-gateway/configuration/).

Environment variables that you set on the `keg` container in `podTemplateSpec` take precedence over the typed fields. Use raw environment variables only for settings that don't have a typed field, such as the `OTEL_` exporter variables.

### Data plane certificates

The data plane authenticates to {{ site.konnect_short_name }} with an mTLS client certificate. By default, the operator provisions this certificate automatically. To supply your own certificate, set `spec.certificateSecret.provisioning` to `Manual` and reference a TLS Secret in the same namespace with `spec.certificateSecret.secretRef`. The operator never modifies a Secret that you supply, and editing it rolls the Deployment.

When the certificate rotates, the operator registers the new certificate in {{ site.konnect_short_name }} and keeps the previous one until the Deployment has rolled out onto the new one.

## TLS and certificates for clients

SNI routing requires TLS between Kafka clients and {{ site.event_gateway_short }}, because the SNI hostname is part of the TLS handshake. Configure TLS with a `tlsServer` listener policy that references a Kubernetes TLS Secret, and configure routing with a `forwardToVirtualCluster` listener policy of type `sni`. For complete examples, see [Deploy {{ site.event_gateway }} with TLSRoute and SNI](/operator/get-started/event-gateway/tlsroute-sni/).

The certificate must cover every bootstrap and broker hostname that {{ site.event_gateway_short }} advertises. The `brokerHostFormat` setting on the SNI policy determines what that takes:

{% table %}
columns:
  - title: "`brokerHostFormat.type`"
    key: type
  - title: Advertised hostnames
    key: hosts
  - title: Certificate SANs
    key: sans
rows:
  - type: "`per_cluster_suffix`"
    hosts: |
      `bootstrap.analytics.keg.example.com`, `broker-0.analytics.keg.example.com`
    sans: |
      One wildcard per virtual cluster, for example `*.analytics.keg.example.com` and `*.payments.keg.example.com`
  - type: "`shared_suffix`"
    hosts: |
      `bootstrap-analytics.keg.example.com`, `broker-0-analytics.keg.example.com`
    sans: |
      One wildcard for all virtual clusters: `*.keg.example.com`
{% endtable %}

With `shared_suffix`, you can add virtual clusters without reissuing the certificate. For more detail, see [Hostname mapping](/event-gateway/architecture/#hostname-mapping).

## DNS

Kafka clients must resolve every advertised bootstrap and broker hostname to the `Gateway` address. Create a wildcard DNS record that points at the address in the `Gateway` status, for example a CNAME record for `*.analytics.keg.example.com`, or for `*.keg.example.com` with `shared_suffix`. A wildcard record covers the bootstrap hostname and every broker, including brokers added later.

<!-- TODO: Confirm with engineering how in-cluster clients should resolve broker hostnames when wildcard DNS isn't available. The reference architecture suggests one ExternalName Service per virtual broker, in a namespace that matches the virtual cluster's DNS label. With the Gateway pattern, those Services would point at the Gateway Service rather than the KegDataPlane Service. -->

## High availability

To keep the gateway available through node and zone failures:

* Spread replicas across at least three availability zones, as described in [Workload placement](#workload-placement).
* Keep `minReplicas` at or above the number of zones.
* Make sure the load balancer that provisions the `Gateway` address spans the same zones.

You can also run several `KegDataPlane` resources that point at the same control plane, for example one per cluster or region, and place a network load balancer or DNS-based routing in front of them.

Kafka clients are built to handle short connection drops. Updates to virtual cluster policies take effect without dropping connections, but other configuration changes, such as listener policy changes, restart the proxy and drop client connections. Plan those changes like any other rollout. For details, see [How it works](/event-gateway/architecture/#how-it-works).

## Backend cluster failover

Because clients connect to a virtual cluster instead of to the backend brokers, you can move clients to a different Kafka cluster without changing their configuration. To fail over, update the `EventGatewayBackendCluster` that the virtual cluster uses so that `bootstrapServers`, and if needed its authentication and TLS settings, point at the standby Kafka cluster.

`EventGatewayVirtualCluster.spec.eventGatewayBackendClusterRef` can't be changed after the virtual cluster has been created in {{ site.konnect_short_name }}, so update the backend cluster in place instead of pointing the virtual cluster at a different `EventGatewayBackendCluster`.

<!-- TODO: Confirm the failover procedure with engineering: whether updating bootstrapServers in place is the supported approach, how client connections behave during the switch, and how consumer group offsets carry over to the standby cluster (for example, with MirrorMaker 2 or Cluster Linking). -->

## Manage configuration with GitOps

Every {{ site.event_gateway_short }} entity has a matching Kubernetes resource, including the control plane (`KonnectEventGateway`), backend clusters, virtual clusters, listeners, listener policies, virtual cluster policies, schema registries, static keys, and TLS trust bundles. This means you can manage both the control plane configuration and the data plane from Git:

* Store all {{ site.event_gateway_short }} resources and the `KegDataPlane` in a Git repository.
* Review changes through pull requests.
* Use a GitOps controller such as Argo CD or Flux to apply the repository to the cluster. The operator then syncs the changes to {{ site.konnect_short_name }}.

Resources depend on each other in the order described in [Resource model](/operator/konnect/event-gateway/#resource-model). Each resource reports a `Programmed` condition when it has been synced to {{ site.konnect_short_name }}, which your pipeline can wait on.

Keep certificates and credentials, such as listener TLS keys and backend cluster passwords, out of Git. Use a secrets management tool such as External Secrets Operator or Sealed Secrets to create the Kubernetes Secrets that the resources reference.

## Observability

{{ site.event_gateway_short }} writes application logs to standard output, so your existing cluster log pipeline can collect them. Set the level and format with `spec.config.observability.logFlags` and `spec.config.observability.logFormat`.

The data plane can export OpenTelemetry metrics and traces. Set the `OTEL_` exporter environment variables on the `keg` container in `podTemplateSpec`, and point them at an OpenTelemetry Collector in your observability namespace. For the available variables, see [Configure observability with OpenTelemetry](/event-gateway/configure-observability-with-otel/). For the metrics that {{ site.event_gateway_short }} emits, see the [metrics reference](/event-gateway/metrics/).

To limit metric cardinality when you have many topics or principals, set `spec.config.observability.metricsRollupAllowMap`.
