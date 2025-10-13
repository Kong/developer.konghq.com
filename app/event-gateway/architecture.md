---
title: "{{site.event_gateway}} architecture"
content_type: reference
layout: reference

description: |
  How does {{ site.event_gateway }} work?
related_resources:
  - text: "{{site.event_gateway}}"
    url: /event-gateway/

products:
    - event-gateway
---

{{site.event_gateway}} is a Kafka proxy that uses the Kafka protocol. 
Kafka software clients connect to the proxy as if it were part of a regular Kafka cluster. 
This lets you productize your Kafka cluster to clients inside and outside of your business.

## {{site.event_gateway_short}} entities

{{site.event_gateway_short}}'s workflow is composed of the following core entities:

{% table %}
columns:
  - title: Entity
    key: entity
  - title: Description
    key: description
  - title: References
    key: Links
rows:
  - entity: Listener
    description: |
      Listeners represent hostname-port or IP-port combinations that connect to TCP sockets. 
      A listener can have policies that enforce TLS certificates and perform SNI routing. 
      The listener runs at Layer 4 of the network stack.
    links: |
      * [Listener entity reference](/event-gateway/entities/listener/)
      * [API reference](/api/knep/)
      * [Listener policies](/event-gateway/policies/?policy-target=listener)
  - entity: Backend cluster
    description: |
      The target Kafka clusters proxied by the gateway are called backend clusters. Backend clusters are similar to gateway services in Kong API Gateway. The Konnect backend cluster entity abstracts the connection details to the actual physical Kafka cluster - the real target Kafka clusters are those that you run in your environment.
      <br><br>
      There can be multiple clusters proxied through the same gateway. Event Gateway control planes store information about how to authenticate to backend clusters, whether or not to verify the cluster’s TLS certificates, and how often to fetch metadata from the cluster. 
    links: |
      * [Backend cluster entity reference](/event-gateway/entities/backend-cluster/)
      * [API reference](/api/knep/)
  - entity: Virtual cluster
    description: |
      Virtual clusters expose a modified view of the backend cluster. From the client’s perspective, the virtual cluster is a real Kafka cluster. Virtual clusters are similar to routes in Kong API Gateway, but there are no HTTP semantics on a virtual cluster.

      The gateway admin can define policies on the virtual clusters that can, for example, define which topics are exposed to which clients, what actions can be taken on the backend cluster, and how records are serialized when the client fetches them. As of now, there can only be one backend cluster exposed through a single virtual cluster.

    links: |
      * [Listener entity reference](/event-gateway/entities/virtual-cluster/)
      * [API reference](/api/knep/)
      * [Listener policies](/event-gateway/policies/?policy-target=virtual-cluster)
  - entity: Policy
    description: |
      Listeners represent hostname-port or IP-port combinations that connect to TCP sockets. 
      A listener can have policies that enforce TLS certificates and perform SNI routing. 
      The listener runs at Layer 4 of the network stack.
    links: |
      * [Policy entity reference](/event-gateway/entities/policy/)
      * [API reference](/api/knep/)
      * [All {{site.event_gateway_short}} policies](/event-gateway/policies/)

{% endtable %}

## Hostname mapping

When a Kafka client connects to the {{site.event_gateway_short}} proxy, the proxy acts as the Kafka bootstrap server. 
The bootstrap server informs the Kafka client about all the brokers in the cluster, and the client then handles balancing requests to all brokers.

To proxy the backend cluster, {{site.event_gateway_short}} receives the hostname metadata from the backend cluster and maps each hostname from the cluster to a hostname that it serves. There are two ways to do with this: with port mapping, or using SNIs.

For example, let's say that there are three brokers in the cluster: `kafka1`, `kafka2`, and `kafka3`.
Each broker exposes port 9092, and the proxy runs on `my-event-gateway`. 
The proxy exposes three different servers for each host in the cluster. Depending on your use requirements, you can expose the brokers to the proxy in the following ways:

* **Port mapping**: The proxy could expose exactly three configurable ports: 

  ```
  kafka1:9092 → my-event-gateway:9092
  kafka2:9092 → my-event-gateway:9093
  kafka3:9092 → my-event-gateway:9094
  ```

  Mapping ports is easier for getting started, but we don't recommend using this method in production, as this is less secure.

* **SNI mapping**: The proxy could expose three different hostnames using SNIs. 
This lets you expose multiple servers on the same physical hardware. In this case, the mapping looks like this:
  
  ```
  kafka1:9092 → host1.my-event-gateway
  kafka2:9092 → host2.my-event-gateway
  kafka3:9092 → host3.my-event-gateway
  ```

  We recommend this method for production.

  You must provide a TLS certificate for every host exposed on the {{site.event_gateway_short}}. 
  This can be done through a certificate with a wildcard SAN, a single certificate with multiple SANs, or multiple certificates in the same bundle. 
  The client must also be able to resolve the hostnames to the IP address of the gateway.