---
title: "{{site.event_gateway}} architecture"
content_type: reference
layout: reference

description: |
  How does {{ site.event_gateway }} work?
related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/
  - text: "Listeners"
    url: /event-gateway/entities/listener/
  - text: "Backend clusters"
    url: /event-gateway/entities/backend-cluster/
  - text: "Virtual clusters"
    url: /event-gateway/entities/virtual-cluster/
  - text: "Policies"
    url: /event-gateway/entities/policy/
  - text: "{{site.event_gateway_short}} policy hub"
    url: /event-gateway/policies/

products:
    - event-gateway

breadcrumbs:
  - /event-gateway/

tools:
  - konnect-api
  - terraform
---

{{site.event_gateway}} is a Kafka proxy that uses the Kafka protocol. 
Kafka software clients connect to the proxy as if it were part of a regular Kafka cluster. 
This lets you productize your Kafka cluster to clients inside and outside of your business.

## How it works

{{site.event_gateway_short}} uses a hybrid deployment model, separating the control plane from the data plane.

* **Control plane ({{site.konnect_short_name}})**: The control plane (CP) is fully managed by Kong within the {{site.konnect_short_name}} platform. 
  It provides a centralized UI and API to manage backend clusters, virtual clusters, listeners, and policies. 
  The control plane generates data plane certificates and pushes configuration updates to the proxy nodes.
  It never sees the actual Kafka message payloads.
* **Data plane (self-managed)**: The data plane (DP) consists of stateless proxy nodes running within your own cluster.
  These nodes intercept Kafka client traffic, evaluate it against the policies pushed by the control plane, and proxy the allowed traffic to the backend Kafka brokers.

Periodically, the data plane polls the control plane for configuration updates.
Once the data plane receives configuration updates, it restarts the running proxy services. 
While listener policy updates do cause a connection drop, updates to virtual cluster policies don't.
If a connection drop occurs, the Kafka client is designed to handle short-lived breaks in connections.

Logically, the components of the high-level architecture can be visualized like this:

<!--vale off-->
{% mermaid %}

flowchart TB

subgraph Konnect ["Konnect (Kong Cloud)"]

  CP["Event Gateway Control Plane"]
end

CP--DP pulls config<br/>from CP-->Customer

subgraph Customer ["Self-managed<br>(on-prem or cloud)"]
  direction LR
   KafkaClient["Kafka Client<br/>Producer + Consumer<br/>(e.g. Java, Python,<br/> Go app)"]
   subgraph EGW ["Event Gateway Data Plane"]
      Analytics["Virtual Cluster: <br/>analytics<br/>policies: e.g. ACL, filter"]
      Payments["Virtual Cluster: <br/>payments<br/>policies: e.g. ACL,<br> Schema, filter"]
   end

   BackendKafka["Backend Kafka<br/>Cluster"]
   KafkaClient<-->EGW<-->BackendKafka

   OB["Observability system<br/>metrics & logs"]
   EGW--OTEL<br/>exporter-->OB
end

style Konnect stroke-dasharray:3
style Customer stroke-dasharray:3

{% endmermaid %}
<!--vale on-->

_**Figure 1**: The control plane (CP) is fully managed in {{site.konnect_short_name}}. When the data plane (DP) polls the CP for configuration, the CP pushes the config to the self-managed DP.
The DP proxies Kafka client traffic through virtual clusters to backend Kafka clusters, and exports metrics and logs to an observability system via OpenTelemetry._

### {{site.event_gateway_short}} entities

In {{site.event_gateway_short}}, an entity is a component or object that makes up the {{site.event_gateway_short}} and its ecosystem. 
Entities represent the various building blocks used to configure and manage {{site.event_gateway_short}}, and each entity has a specific role.
All the configurations of the entities that run on the data plane live in the control plane. 

{{site.event_gateway_short}}'s workflow is composed of the following core entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
  - title: References
    key: links
rows:
  - entity: Listener
    description: |
      Listeners represent IP/TCP port combinations at which the gateway listens
      for connections from clients.
      A listener can have policies that enforce TLS certificates and perform SNI routing. 
      The listener runs at Layer 4 of the network stack.
    links: |
      * [Listener entity reference](/event-gateway/entities/listener/)
      * [API reference](/api/konnect/event-gateway/#/operations/list-event-gateway-listeners)
      * [Listener policies](/event-gateway/policies/?policy-target=listener)
  - entity: Backend cluster
    description: |
      The target Kafka clusters proxied by the gateway are called backend clusters. Backend clusters are similar to gateway services in Kong API Gateway. The Konnect backend cluster entity abstracts the connection details to the actual physical Kafka cluster running in your environment.
      <br><br>
      There can be multiple backend clusters proxied by the same gateway. {{site.event_gateway_short}} control planes store information about how to authenticate to backend clusters, whether or not to verify the cluster’s TLS certificates, and how often to fetch metadata from the cluster.
    links: |
      * [Backend cluster entity reference](/event-gateway/entities/backend-cluster/) <br><br>
      * [API reference](/api/konnect/event-gateway/#/operations/list-event-gateway-backend-clusters)
  - entity: Virtual cluster
    description: |
      Virtual clusters expose a modified view of the backend cluster. From the client’s perspective, the virtual cluster is a real Kafka cluster. Virtual clusters are similar to routes in Kong API Gateway, but there are no HTTP semantics on a virtual cluster.
      <br><br>
      The gateway admin can define policies on the virtual clusters that can, for example, define which topics are exposed to which clients or what actions can be taken on the backend cluster.
      <br><br>
      As of now, a virtual cluster can only be associated with exactly one backend cluster and so cannot aggregate data from multiple backend clusters.

    links: |
      * [Virtual cluster entity reference](/event-gateway/entities/virtual-cluster/)
      * [API reference](/api/konnect/event-gateway/#/operations/list-event-gateway-virtual-clusters)
      * [Virtual cluster policies](/event-gateway/policies/?policy-target=virtual-cluster)
  - entity: Policy
    description: |
      Policies control how Kafka protocol traffic is modified between the client and the backend cluster.
      <br><br>
      There are two main types of policies:
      * Virtual cluster policies: Transformation and validation policies applied to Kafka messages. 
      Virtual cluster policies break down further into cluster, consume, and produce policies.
      * Listener policies: Routing policies that pass traffic to the virtual cluster.
      
    links: |
      * [Policy entity reference](/event-gateway/entities/policy/)
      * [API reference](/api/konnect/event-gateway/#/operations/list-event-gateway-listener-policies)
      * [All {{site.event_gateway_short}} policies](/event-gateway/policies/)

{% endtable %}

## Hostname mapping

When a Kafka client connects to the {{site.event_gateway_short}} proxy, the proxy acts as the Kafka bootstrap server. 
The bootstrap server informs the Kafka client about all the brokers in the cluster, and the client then handles balancing requests to all brokers.

To proxy the backend cluster, {{site.event_gateway_short}} receives the hostname metadata from the backend cluster and maps each hostname from the cluster to a hostname that it serves. There are two ways to do this: port mapping, or using TLS with SNI. You configure both options on a listener policy.

For example, let's say that there are three brokers in the cluster: `kafka1`, `kafka2`, and `kafka3`.
Each broker exposes port `9092`, and the proxy is listening on the IP `10.0.0.1`.
The proxy exposes a different server for each host in the cluster.
Depending on your use requirements, you can expose the brokers to the proxy in one of the following ways: with [port mapping](#port-mapping) or with [SNI mapping](#sni-mapping).

### Port mapping

Let's use an example where the proxy exposes the following ports:

```
10.0.0.1:9092 → kafka1:9092 (bootstrap port)
10.0.0.1:9093 → kafka1:9092
10.0.0.1:9094 → kafka2:9092
10.0.0.1:9095 → kafka3:9092
```

Kafka clients are meant to be configured only with a bootstrap port.
Mapping ports is easier for getting started, but we don't recommend using this method in production because it's less flexible.

For an example configuration, see [Forward via port mapping](/event-gateway/policies/forward-to-virtual-cluster/examples/port-mapping/).

### SNI mapping

The proxy exposes multiple hostnames using SNI.
This lets you expose multiple servers on the same port. Using our example ports, the mapping looks like this:
  
```
bootstrap.my-event-gateway.acme:9092 → kafka1:9092 (bootstrap hostname)
broker-1.my-event-gateway.acme:9092 → kafka1:9092
broker-2.my-event-gateway.acme:9092 → kafka2:9092
broker-3.my-event-gateway.acme:9092 → kafka3:9092
```

Kafka clients are meant to be configured only with a bootstrap hostname.
We recommend this method for production.

You must provide a TLS certificate for every host exposed on the {{site.event_gateway_short}}. 
This can be done through a certificate with a wildcard SAN, a single certificate with multiple SANs, or multiple certificates in the same bundle.

#### Shared suffix {% new_in 1.1 %}
Alternatively, you can set `broker_host_format.type` to `shared_suffix` in the listener policy, so that you can use one wildcard SAN for all virtual clusters. In this case, the mapping looks like this

```
bootstrap-my-event-gateway.acme:9092 → kafka1:9092 (bootstrap hostname)
broker-1-my-event-gateway.acme:9092 → kafka1:9092
broker-2-my-event-gateway.acme:9092 → kafka2:9092
broker-3-my-event-gateway.acme:9092 → kafka3:9092
```

In all cases, the client must also be able to resolve the hostnames to the IP address of the gateway.

For example configurations, see:
* [Forward via SNI routing](/event-gateway/policies/forward-to-virtual-cluster/examples/sni-routing/)
* [Forward via SNI routing with shared suffix](/event-gateway/policies/forward-to-virtual-cluster/examples/sni-routing-shared-suffix/)
