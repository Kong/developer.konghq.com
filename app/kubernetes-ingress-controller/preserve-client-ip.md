---
title: "Preserve client IP"
breadcrumbs:
  - /kubernetes-ingress-controller/
description: |
  Learn how to pass the client IP through Gateway to the upstream service

content_type: reference
layout: reference

products:
  - kic

works_on:
  - on-prem
  - konnect
---


{{site.base_gateway}} is deployed using a Kubernetes Service of type `LoadBalancer`. This can result in the loss of the actual client IP address, and can lead to {{site.base_gateway}} observing the IP address of the Load Balancer as the client IP address. This guide lays out different methods of solving this problem.

Preserving the client IP address in the cloud behind Load Balancers requires configuration that is specific to your use case, cloud provider, and other architecture details. 
The documentation for [Using Source IP](https://kubernetes.io/docs/tutorials/services/source-ip/) provides details on how networking and the various methods work inside Kubernetes. We recommend that you read this document.

To preserve the client IP address, you can use one of the following methods:

* ExternalTrafficPolicy
* Proxy Protocol
* HTTP headers

## ExternalTrafficPolicy: Local

As explained in the [Kubernetes docs](https://kubernetes.io/docs/tasks/access-application-cluster/create-external-load-balancer/#preserving-the-client-source-ip), setting `service.spec.externalTrafficPolicy` to `Local` preserves the client IP address. You don't need to change any configuration in {{site.base_gateway}} if you are using this method to preserve the client IP address.

{:.warning}
> This method is not supported by all cloud providers.

## Proxy Protocol

If you have an L4 Load Balancer that supports Proxy Protocol, and you're terminating TCP connections at the Load Balancer before passing traffic onward to {{site.base_gateway}}, then you can configure {{site.base_gateway}} to set the client IP address through this protocol.

Once you have configured the Load Balancer to use Proxy Protocol, you need to set the following environment variables in {{site.base_gateway}} to receive the client IP from the Proxy Protocol header:

- [`KONG_TRUSTED_IPS`](/gateway/latest/reference/configuration/#trusted_ips)
- [`KONG_PROXY_LISTEN`](/gateway/latest/reference/configuration/#proxy_listen)
- [`KONG_REAL_IP_HEADER`](/gateway/latest/reference/configuration/#real_ip_header)

For example:

```bash
KONG_TRUSTED_IPS=0.0.0.0/0,::/0  # This trusts all IPs
KONG_PROXY_LISTEN="0.0.0.0:8000 proxy_protocol, 0.0.0.0:8443 ssl proxy_protocol"
KONG_REAL_IP_HEADER=proxy_protocol
```

## HTTP headers

If you are using an L7 Load Balancer where HTTP requests are being terminated at the Load Balancer, you need to use the `x-forwarded-for` or `x-real-ip` header to preserve details of the connection between the client and Load Balancer.

You should configure the Load Balancer to inject these headers, and then you need to set the following environment variables in {{site.base_gateway}} to pick up the client IP address from HTTP headers:

<!--vale off-->
{% kong_config_table %}
config:
  - name: trusted_ips
  - name: real_ip_header
  - name: real_ip_recursive
{% endkong_config_table %}
<!--vale on-->

`real_ip_recursive` is optional.

## Cloud-provider specific details

For the major public clouds, there are some additional
details that can help you preserve the client IP address.

### GKE

You can use `ExternalTrafficPolicy: Local` to preserve the client IP address.

### AKS

You can use `ExternalTrafficPolicy: Local` to preserve the client IP address.

### EKS

You have three options:

- L4 Network Load Balancer, with [AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller): 
  In this case, you can use the Proxy Protocol method to preserve the client IP
  address together with `ExternalTrafficPolicy: Cluster`.
- L4 in-tree network Load Balancer with the `service.beta.kubernetes.io/aws-load-balancer-type: nlb` annotation: 
  In this case, you need to use `ExternalTrafficPolicy: Local` to preserve the client IP address.
- L7 Load Balancer: 
  In this case, you need to use the HTTP headers method to preserve the client
  IP address.

The recommended Load Balancer type for AWS is the Network Load Balancer deployed with the AWS Load Balancer Controller. 
You can choose this type of Load Balancer using the following annotations:

```bash
service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
service.beta.kubernetes.io/aws-load-balancer-type: "external"
service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: "instance"
```

To enable proxy protocol with the AWS Load Balancer Controller, you need to set these annotations:

```bash
service.beta.kubernetes.io/aws-load-balancer-proxy-protocol: "*"
```

See the [list of annotations for the AWS Load Balancer Controller](https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/guide/service/annotations/) for all options.
