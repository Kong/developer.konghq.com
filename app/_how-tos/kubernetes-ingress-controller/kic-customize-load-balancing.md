---
title: Customize load balancing with KongUpstreamPolicy
short_title: Load Balancing
description: "Change the load balancing algorithm to consistent-hashing based on an incoming header"
content_type: how_to

permalink: /kubernetes-ingress-controller/load-balancing/

breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Advanced Usage

products:
  - kic

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I change the load balancing algorithm to consistent-hashing?
  a: Create a `KongUpstreamPolicy` resource then add the `konghq.com/upstream-policy` annotation to your Service

related_resources:
  - text: KongUpstreamPolicy reference
    url: /kubernetes-ingress-controller/reference/custom-resources/

prereqs:
  kubernetes:
    gateway_api: true
  entities:
    services:
      - echo-service
    routes:
      - echo

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## Deploy additional echo replicas

To demonstrate Kong's load balancing functionality we need multiple `echo` Pods. Scale out the `echo` deployment.

```bash
kubectl scale -n kong --replicas 2 deployment echo
```

## Use KongUpstreamPolicy with a Service resource

By default, Kong will round-robin requests between upstream replicas. If you run `curl -s $PROXY_IP/echo | grep "Pod"` repeatedly, you should see the reported Pod name alternate between two values.

You can configure the Kong Upstream associated with the Service to use a different [load balancing strategy](/gateway/load-balancing/), such as consistently sending requests to the same upstream based on a header value. See the [KongUpstreamPolicy reference](/kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy) for the full list of supported algorithms and their configuration options. 

Let's create a KongUpstreamPolicy resource defining the new behavior:

```bash
echo '
apiVersion: configuration.konghq.com/v1beta1
kind: KongUpstreamPolicy
metadata:
  name: sample-customization
  namespace: kong
spec:
  algorithm: consistent-hashing
  hashOn:
    header: demo
  hashOnFallback:
    input: ip
  ' | kubectl apply -f -
```

Now, let's associate this KongUpstreamPolicy resource with our Service resource
using the `konghq.com/upstream-policy` annotation.

```bash
kubectl patch -n kong service echo \
  -p '{"metadata":{"annotations":{"konghq.com/upstream-policy":"sample-customization"}}}'
```

With consistent hashing and client IP fallback, sending repeated requests without any `x-lb` header now sends them to the same Pod:

```bash
for n in {1..5}; do curl -s $PROXY_IP/echo | grep "Pod"; done
```

```bash
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-frpjc.
```
{:.no-copy-code}

If you add the header, Kong hashes its value and distributes it to the
same replica when using the same value:

```bash
for n in {1..3}; do
  curl -s $PROXY_IP/echo -H "demo: foo" | grep "Pod";
  curl -s $PROXY_IP/echo -H "demo: bar" | grep "Pod";
  curl -s $PROXY_IP/echo -H "demo: baz" | grep "Pod";
done
```

```bash
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-frpjc.
Running on Pod echo-965f7cf84-wlvw9.
```
{:.no-copy-code}

Increasing the replicas redistributes some subsequent requests onto the new
replica:

```bash
kubectl scale -n kong --replicas 3 deployment echo
```

```bash
for n in {1..3}; do
  curl -s $PROXY_IP/echo -H "demo: foo" | grep "Pod";
  curl -s $PROXY_IP/echo -H "demo: bar" | grep "Pod";
  curl -s $PROXY_IP/echo -H "demo: baz" | grep "Pod";
done
```

```bash
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-wlvw9.
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-5h56p.
Running on Pod echo-965f7cf84-wlvw9.
```
{:.no-copy-code}


Kong's load balancer doesn't directly distribute requests to each of the Service's endpoints. It first distributes them evenly across a number of equal-size buckets. These buckets are then distributed across the available endpoints according to their weight. For Ingresses, however, there is only one Service, and the controller assigns each endpoint (represented by a Kong Upstream Target) equal weight. In this case, requests are evenly hashed across all endpoints.

Gateway API HTTPRoute rules support distributing traffic across multiple Services. The rule can assign weights to the Services to change the proportion of requests an individual Service receives. In Kong's implementation, all endpoints of a Service have the same weight. Kong calculates a per-endpoint Upstream Target weight such that the aggregate target weight of the endpoints is equal to the proportion indicated by the HTTPRoute weight.

For example, say you have two Services with the following configuration:

 * One Service has four endpoints
 * The other Service has two endpoints
 * Each Service has weight `50` in the HTTPRoute

The Targets created for the two-endpoint Service have double the weight of the Targets created for the four-endpoint Service (two weight `16` Targets and four weight `8` Targets). Scaling the four-endpoint Service to eight would halve the weight of its Targets (two weight `16` Targets and eight weight `4` Targets).

KongUpstreamPolicy can also configure Upstream health checking behavior as well. See [the KongUpstreamPolicy reference](/kubernetes-ingress-controller/reference/custom-resources/#kongupstreampolicy) for the health check fields.
