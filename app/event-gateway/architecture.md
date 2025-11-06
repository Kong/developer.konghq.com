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
---

{{site.event_gateway}} is a Kafka proxy that uses the Kafka protocol. 
Kafka software clients connect to the proxy as if it were part of a regular Kafka cluster. 
This lets you productize your Kafka cluster to clients inside and outside of your business.

## {{site.event_gateway_short}} entities

In {{site.event_gateway_short}}, an entity is a component or object that makes up the {{site.event_gateway_short}} and its ecosystem. 
Entities represent the various building blocks used to configure and manage {{site.event_gateway_short}}, and each entity has a specific role.

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

To proxy the backend cluster, {{site.event_gateway_short}} receives the hostname metadata from the backend cluster and maps each hostname from the cluster to a hostname that it serves. There are two ways to do with this: with port mapping, or using TLS with SNI. You configure both options on a [listener](/event-gateway/entities/listener/).

For example, let's say that there are three brokers in the cluster: `kafka1`, `kafka2`, and `kafka3`.
Each broker exposes port `9092`, and the proxy is listening on the IP `10.0.0.1`.
The proxy exposes three different servers for each host in the cluster.
Depending on your use requirements, you can expose the brokers to the proxy in the following ways:

* **Port mapping**: The proxy exposes exactly three configurable ports:

  ```
  10.0.0.1:9092 → kafka1:9092
  10.0.0.1:9093 → kafka2:9092
  10.0.0.1:9094 → kafka3:9092
  ```

  Mapping ports is easier for getting started, but we don't recommend using this method in production because it's less flexible.

* **SNI mapping**: The proxy exposes three different hostnames using SNI.
This lets you expose multiple servers on the same port. In this case, the mapping looks like this:
  
  ```
  broker-1.my-event-gateway:9092 → kafka1:9092
  broker-2.my-event-gateway:9092 → kafka2:9092
  broker-3.my-event-gateway:9092 → kafka3:9092
  ```

  We recommend this method for production.

  You must provide a TLS certificate for every host exposed on the {{site.event_gateway_short}}. 
  This can be done through a certificate with a wildcard SAN, a single certificate with multiple SANs, or multiple certificates in the same bundle. 
  The client must also be able to resolve the hostnames to the IP address of the gateway.
