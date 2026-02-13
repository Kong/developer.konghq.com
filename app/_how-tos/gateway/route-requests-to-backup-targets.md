---
title: Route requests to backup Targets during failures
permalink: /how-to/route-requests-to-backup-targets/
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
  - load-balancing
search_aliases:
  - backup target

tldr:
    q: How do I route requests to different Targets in case my other Targets are unhealthy?
    a: "Create a Service, a Route, and an Upstream with one of the `latency`, `least-connections`, or `round-robin` load balancing strategies. Configure primary Targets on the Upstream with `failover: false` and a failover Target with `failover: true`."

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

faqs:
  - q: Can I set more than one failover Target?
    a: Yes, Upstream supports multiple failover Targets.
---

## Start three Target backends

In this tutorial, we're going to have two primary Targets and one [failover Target](/gateway/entities/target/#managing-failover-targets). In this configuration, traffic will be routed to only the primary Targets if they are both healthy. If they are *both* unhealthy, traffic will be routed to the failover Target.

We'll use three backends to represent our three Targets using Docker’s ultra-small `hashicorp/http-echo` image:

```sh
docker run -d --rm --name primary1 -p 9001:5678 hashicorp/http-echo -text "PRIMARY-1"
docker run -d --rm --name primary2 -p 9002:5678 hashicorp/http-echo -text "PRIMARY-2"
docker run -d --rm --name failover -p 9003:5678 hashicorp/http-echo -text "FAILOVER"
```

## Configure a Gateway Service, Route, and Upstream

Configure a Gateway Service and Route to point to the Upstream:
{% entity_examples %}
entities:
  upstreams:
    - name: example-upstream
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

1. Configure the first primary Target:
{% capture primary %}
<!--vale off -->
{% control_plane_request %}
url: /upstreams/example-upstream/targets/
method: POST
headers:
  - 'Accept: application/json'
body:
  target: host.docker.internal:9001
  weight: 100
  failover: false
status_code: 201
{% endcontrol_plane_request %}
<!--vale on -->
{% endcapture %}
{{ primary | indent: 3}}

1. Configure the second primary Target:
{% capture secondary %}
<!--vale off -->
{% control_plane_request %}
url: /upstreams/example-upstream/targets/
method: POST
headers:
  - 'Accept: application/json'
body:
  target: host.docker.internal:9002
  weight: 100
  failover: false
status_code: 201
{% endcontrol_plane_request %}
<!--vale on -->
{% endcapture %}
{{ secondary | indent: 3}}

1. Configure the failover Target:
{% capture failover %}
<!--vale off -->
{% control_plane_request %}
url: /upstreams/example-upstream/targets/
method: POST
headers:
  - 'Accept: application/json'
body:
  target: host.docker.internal:9003
  weight: 50
  failover: true
status_code: 201
{% endcontrol_plane_request %}
<!--vale on -->
{% endcapture %}
{{ failover | indent: 3}}

## Verify that the primary Targets handle traffic

Run the following to verify that only the primary Targets handle traffic because they are both healthy:

```sh
for i in {1..10}; do curl -sS http://localhost:8000/anything; echo; done
```

You'll get an output like the following, where you can see the Targets cycling between `PRIMARY-1` and `PRIMARY-2`:
```sh
PRIMARY-2

PRIMARY-1

PRIMARY-1

PRIMARY-2

PRIMARY-2

PRIMARY-2
```
{:.no-copy-code}

## Validate failover

To validate that the failover Target works, let's mark the primary Targets as unhealthy by shutting down the hosts. Run the following:
```sh
docker stop primary1 primary2
```

You can now validate that since the primary Targets are *both* unhealthy, only the failover Target routes traffic:
```sh
for i in {1..6}; do curl -s http://localhost:8000/anything; echo; done
```
This time, the response should show the `FAILOVER` Target instead of `PRIMARY`.
