---
title: Ingress

description: |
  {{ site.kic_product_name }} can be configured with Ingress resources. Understand how Ingress and IngressClass work with Kong.

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect

related_resources:
  - text: Gateway API
    url: /kubernetes-ingress-controller/gateway-api/
---

{:.info}
> Kong will continue to support the [Kubernetes Ingress resource](https://kubernetes.io/docs/concepts/services-networking/ingress/) to configure a {{site.base_gateway}} for the foreseeable future. However, as the [Kubernetes Gateway API resource](https://kubernetes.io/docs/concepts/services-networking/gateway/) is now the preferred mechanism for configuring inbound routing in Kubernetes clusters, we recommend that you use the Gateway API to configure a {{site.base_gateway}}.

The {{site.kic_product_name}} uses ingress classes to filter Kubernetes Ingress objects and other resources before converting them into {{site.base_gateway}} configuration. This allows the Controller to coexist with other ingress controllers and other deployments of the {{site.kic_product_name}} in the same cluster. A {{site.kic_product_name}} instance only processes configuration marked for its use.

## Configure the controller ingress class

The `--ingress-class` flag (or `CONTROLLER_INGRESS_CLASS` environment variable) specifies the ingress class expected by the {{site.kic_product_name}}. If you don't set a value, {{ site.kic_product_name }} will default to `--ingress-class=kong`.

## Load resources by class

The {{site.kic_product_name}} translates a number of Kubernetes resources into {{site.base_gateway}} configuration. These resources can be sorted into two categories:

- Resources that the controller translates directly into {{site.base_gateway}} configuration.

  For example, an `Ingress` is translated directly into a [Kong Route](/gateway/entities/route/), and a `KongConsumer` is translated directly into a [Kong Consumer](/gateway/entities/consumer/).
- Resources referenced by some other resource, where the other resource is directly translated into {{site.base_gateway}} configuration.
 
  For example, a Secret containing an authentication plugin credential is _not_ translated directly. It's only translated into {{site.base_gateway}} configuration if a `KongConsumer` resource references it.


Because they create {{site.base_gateway}} configuration independent of any other resources, directly-translated resources require an ingress class, and their class must match the class configured for the controller. Referenced resources do not require a class, but must be referenced by a directly translated resource that matches the controller.

### Add class information to resources

Most resources use a [`kubernetes.io/ingress-class` annotation](/kubernetes-ingress-controller/reference/annotations/#kubernetesioingressclass)
to indicate their class. However, v1 Ingress resources have a [dedicated `ingressClassName` field](https://kubernetes.io/docs/concepts/services-networking/ingress/#deprecated-annotation) that should contain the `ingressClassName`.

## When to use a custom class

Using the default `kong` class is fine for simple deployments, where only one
{{site.kic_product_name}} instance is running in a cluster.

You need to use a custom class when:

- You install multiple Kong environments in one Kubernetes cluster to handle different types of ingress traffic. For example, when using separate Kong instances to handle traffic on internal and external load balancers, or deploying different types of non-production environments in a single test cluster.
- You install multiple controller instances alongside a single Kong cluster to separate configuration into different Kong workspaces (DB-backed mode only) using the `--kong-workspace` flag or to restrict which Kubernetes namespaces any one controller instance has access to.

## Examples

Typical configurations include a mix of resources that have class information and resources that are referenced by them. For example, consider this configuration for authenticating a request, using a KongConsumer, credential Secret, Ingress, and KongPlugin (a Service is implied, but not shown):

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: alice
  annotations:
    kubernetes.io/ingress.class: "kong"
username: alice
credentials:
- alice-key

---

kind: Secret
apiVersion: v1
metadata:
  name: alice-key
  labels:
    konghq.com/credential: key-auth
stringData:
  key: bylkogdatomoryakom

---

apiVersion: configuration.konghq.com/v1
kind: KongPlugin
metadata:
  name: key-auth-example
plugin: key-auth

---

kind: Ingress
apiVersion: networking.k8s.io/v1
metadata:
  name: echo-ingress
  annotations:
    konghq.com/plugins: "key-auth-example"
spec:
  ingressClassName: kong
  rules:
  - http:
      paths:
      - path: /echo
        pathType: ImplementationSpecific
        backend:
          service:
            name: echo
            port:
              number: 1027

```

The KongConsumer and Ingress resources both have class annotations, as they are resources that the controller uses as a basis for building {{site.base_gateway}} configuration. The Secret and KongPlugin _do not_ have class annotations, as they are referenced by other resources that do.

