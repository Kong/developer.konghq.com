---
title: Custom Resources

description: |
  Which custom resources does {{ site.kic_product_name }} provide? How are they used to configure {{ site.base_gateway }}?

content_type: reference
layout: reference
breadcrumbs: 
  - /kubernetes-ingress-controller/
search_aliases: 
  - KIC custom resources
products:
  - kic
tags: 
  - custom-resources
works_on:
  - on-prem
  - konnect

related_resources:
  - text: Custom Resource API Reference
    url: /kubernetes-ingress-controller/reference/custom-resources/
---


[Custom Resources (CRDs)](https://kubernetes.io/docs/tasks/access-kubernetes-api/extend-api-custom-resource-definitions/) in Kubernetes allow controllers to extend Kubernetes-style declarative APIs that are specific to certain applications. 

A few custom resources are bundled with the {{site.kic_product_name}} to configure settings that are specific to {{site.base_gateway}} and provide fine-grained control over the proxying behavior.

The {{site.kic_product_name}} uses the `configuration.konghq.com` API group for storing configuration specific to {{site.base_gateway}}.

These CRDs allow users to declaratively configure all aspects of {{site.base_gateway}}:

- [KongPlugin](#kongplugin)
- [KongClusterPlugin](#kongclusterplugin)
- [KongConsumer](#kongconsumer)
- [KongConsumerGroup](#kongconsumergroup)
- [TCPIngress](#tcpingress)
- [UDPIngress](#udpingress)

## KongPlugin

{{site.base_gateway}} is designed around an extensible [plugin](/gateway/entities/plugin/) architecture and comes with a wide variety of plugins already bundled inside it.  These plugins can be used to modify the request or impose restrictions on the traffic.

Once this resource is created, the resource needs to be associated with an Ingress, Service, HTTPRoute, KongConsumer or KongConsumerGroup resource in Kubernetes.

This diagram shows how you can link a KongPlugin resource to an Ingress, Service, or KongConsumer.

<!--vale off-->
{% mermaid %}
flowchart TD
    subgraph Link to consumer
        direction TB
        E(apiVersion: configuration.konghq.com/v1<br>kind: KongPlugin<br>metadata:<br>&nbsp;&nbsp;&nbsp;name: custom-api-limit<br>plugin: rate-limiting<br>config:<br>&nbsp;&nbsp;&nbsp;minute: 10):::left
        F(apiVersion: configuration.konghq.com<br>kind: KongConsumer<br>metadata:<br>&nbsp;&nbsp;&nbsp;name: demo-api<br>&nbsp;&nbsp;&nbsp;annotations:<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;konghq.com/plugins: custom-api-limit<br>username: special-client):::left
    end
    
    subgraph Link to Ingress and service
        direction TB
        A(apiVersion: configuration.konghq.com/v1<br>kind: KongPlugin<br>metadata:<br>&nbsp;&nbsp;&nbsp;name: reports-api-limit<br>plugin: rate-limiting<br>config: <br>&nbsp;&nbsp;&nbsp;minute: 5):::left 
        B(apiVersion: extensions/v1beta1<br>kind: Ingress<br>metadata:<br>&nbsp;&nbsp;&nbsp;name: demo-api<br>&nbsp;&nbsp;&nbsp;annotations:<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;konghq.com/plugins: reports-api-limit):::left
        C(apiVersion: v1<br>kind: Service<br>metadata:<br>&nbsp;&nbsp;&nbsp;name: billing-api<br>&nbsp;&nbsp;&nbsp;annotations:<br>&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;konghq.com/plugins: billing-auth):::left
        D(apiVersion: configuration.konghq.com/v1<br>kind: KongPlugin<br>metadata:<br>&nbsp;&nbsp;&nbsp;name: billing-auth<br>plugin: basic auth):::left
    end

    A --> |execute the plugin for any request that matches a rule in the following ingress resource|B
    B --> C
    D --> |execute the plugin for any request that is forwarded to the billing-api service in k8s|C
    E --> |Associated using konghq.com/plugins annotation|F
{% endmermaid %}
<!--vale on-->

## KongClusterPlugin

_This resource requires the [`kubernetes.io/ingress.class` annotation](/kubernetes-ingress-controller/reference/annotations/)._

KongClusterPlugin resource is exactly same as KongPlugin, except that it is a Kubernetes cluster-level resource rather than a namespaced resource. This can help when the configuration of the plugin needs to be centralized and the permissions to add or update plugin configuration rests with a different persona other than the application owners.

This resource can be associated with an Ingress, [Service](/gateway/entities/service/), or KongConsumer, and can be used in the exact same way as KongPlugin.

A namespaced KongPlugin resource takes priority over a KongClusterPlugin with the same name.

## KongConsumer

_This resource requires the [`kubernetes.io/ingress.class` annotation](/kubernetes-ingress-controller/reference/annotations/). Its value must match the value of the controller's `--ingress-class` argument, which is `kong` by default._

This custom resource configures Consumers in {{site.base_gateway}}.  Every KongConsumer resource in Kubernetes directly translates to a [Consumer](/gateway/entities/consumer/) object in {{site.base_gateway}}.

## TCPIngress

{:.warning}
> **Important: TCPIngress Deprecation Notice**
>
> The `TCPIngress` custom resource is **deprecated** as of {{site.kic_product_name}} 3.5 and will be **completely removed in {{ site.operator_product_name }} 2.0.0**. This resource was created to address limitations of the traditional Kubernetes Ingress API, but since the Gateway API has reached maturity and widespread adoption, it's now redundant and causes confusion.
>
> **Migration is required** before upgrading to {{ site.operator_product_name }} 2.0.0. Use the [Migrating from Ingress to Gateway API](/kubernetes-ingress-controller/migrate/ingress-to-gateway/) guide to migrate your existing `TCPIngress` resource to its Gateway API equivalents (`TCPIngress` → `Gateway` + `TCPRoute` + `TLSRoute`).

_This resource requires the [`kubernetes.io/ingress.class` annotation](/kubernetes-ingress-controller/reference/annotations/). Its value must match the value of the controller's `--ingress-class` argument, which is `kong` by default._

This Custom Resource is used for exposing non-HTTP and non-GRPC services running inside Kubernetes to the outside world through {{site.base_gateway}}. This proves to be useful when you want to use a single cloud LoadBalancer for all kinds of traffic into your Kubernetes cluster.

It is very similar to the Ingress resource that ships with Kubernetes.

## UDPIngress

{:.warning}
> **Important: UDPIngress Deprecation Notice**
>
> The `UDPIngress` custom resource is **deprecated** as of {{site.kic_product_name}} 3.5 and will be **completely removed in {{ site.operator_product_name }} 2.0.0**. This resource was created to address limitations of the traditional Kubernetes Ingress API, but since the Gateway API has reached maturity and widespread adoption, it's now redundant and causes confusion.
>
> **Migration is required** before upgrading to {{ site.operator_product_name }} 2.0.0. Use the [Migrating from Ingress to Gateway API](/kubernetes-ingress-controller/migrate/ingress-to-gateway/) guide to migrate your existing `UDPIngress` resource to its Gateway API equivalents (`UDPIngress` → `Gateway` + `UDPRoute`).

_This resource requires the [`kubernetes.io/ingress.class` annotation](/kubernetes-ingress-controller/reference/annotations/). Its value
must match the value of the controller's `--ingress-class` argument, which is
`kong` by default._

This Custom Resource is used for exposing [UDP](https://datatracker.ietf.org/doc/html/rfc768) services
running inside Kubernetes to the outside world through {{site.base_gateway}}.

This is useful for services such as DNS servers, game servers,
VPN software and a variety of other applications.

## KongConsumerGroup

_This resource requires the [`kubernetes.io/ingress.class` annotation](/kubernetes-ingress-controller/reference/annotations/). Its value must match the value of the controller's `--ingress-class` argument, which is `kong` by default._

KongConsumerGroup creates a [Consumer Group](/gateway/entities/consumer-group/), which associates KongPlugin resources with a collection of KongConsumers.

KongConsumers have a `consumerGroups` array. Adding a KongConsumerGroup's name to that array adds that Consumer to that Consumer Group.

Applying a `konghq.com/plugins: <KongPlugin name>` annotation to a KongConsumerGroup then executes that plugin on every consumer in the consumer group.
