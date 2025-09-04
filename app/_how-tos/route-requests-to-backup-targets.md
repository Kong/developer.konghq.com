---
title: Route requests to backup Targets during failures
content_type: how_to

description: Use the Route by Header plugin to route requests based on a header value.

products:
    - gateway

works_on:
    - on-prem

min_version:
  gateway: '3.12'

entities: 
  - service
  - route
  - upstream
  - target

tags:
  - failover
search_aliases:
  - backup target

tldr:
    q: How do I route requests to different Targets in case my other Targets are unhealthy?
    a: "Create a Service, a Route, and an Upstream with either the `latency`, `least-connections`, or `round-robin` load balancing strategy. Configure primary targets on the Upstream with `failover: false` and a failover Target with `failover: true`."

tools:
    - deck
related_resources:
  - text: Upstream entity
    url: /gateway/entities/upstream/
  - text: Target entity
    url: /gateway/entities/target/

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Start three Target backends

In this tutorial, we're going to have two primary Targets and one [failover Target](/gateway/entities/target/#managing-failover-targets). In this configuration, traffic will be routed to only the primary Targets if they are both healthy. If they are *both* unhealthy, traffic will be routed to the failover Target.

We'll use three backends to represent our three Targets using Docker’s ultra-small `hashicorp/http-echo` image:

```sh
docker run -d --rm --name primary1 -p 9001:5678 hashicorp/http-echo -text "PRIMARY-1"
docker run -d --rm --name primary2 -p 9002:5678 hashicorp/http-echo -text "PRIMARY-2"
docker run -d --rm --name failover -p 9003:5678 hashicorp/http-echo -text "FAILOVER"
```

## Configure a Gateway Service and Route

Configure a Gateway Service and Route to point to the Upstream you created in the prerequisites:
{% entity_examples %}
entities:
  services:
    - name: example-service
      host: example-upstream 
      protocol: http
  routes:
    - name: example-route
      paths:
      - "/anything"
      service:
        name: example-service
{% endentity_examples %}

## Configure the Upstream Targets

Now, you can configure Upstream with the two primary Targets `failover: false` and one failover Target `failover: true`. 

{% entity_examples %}
entities:
  upstreams:
    - name: example-upstream
      targets:
        - target: host.docker.internal:9001
          weight: 100
          failover: false
        - target: host.docker.internal:9002
          weight: 100
          failover: false
        - target: host.docker.internal:9003
          weight: 50
          failover: true
{% endentity_examples %}

## Verify the primary Targets handle traffic

Run the following to verify that only the primary Targets handle traffic because they are both healthy:

```sh
for i in {1..10}; do curl -sS http://localhost:8000/anything; echo; done
```

You'll get an output like the following:
```sh
PRIMARY-2

PRIMARY-1

PRIMARY-1

PRIMARY-2

PRIMARY-2

PRIMARY-2
```
{:.no-copy-code}

## Mark primary Targets as unhealthy

To mark the primary Targets as unhealthy, you can run the following:
```sh
docker stop primary1 primary2
```

## Validate

You can now validate that since the primary Targets are *both* unhealthy, only the failover Target routes traffic:
```sh
for i in {1..6}; do curl -s http://localhost:8000/anything; echo; done
```
