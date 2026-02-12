---
title: Get started with {{site.base_gateway}}
description: Learn how to set up a local {{site.base_gateway}} installation and configure it for some common API management tasks. 
content_type: how_to

permalink: /gateway/get-started/
breadcrumbs:
  - /gateway/

products:
    - gateway

works_on:
    - on-prem
    - konnect

plugins:
  - rate-limiting
  - key-auth
  - proxy-cache

entities: 
  - service
  - plugin
  - consumer
  - target
  - upstream

tags:
    - get-started

tldr: 
  q: What is {{site.base_gateway}}, and how can I get started with it?
  a: |
    [{{site.base_gateway}}](/gateway/) is a lightweight, fast, and flexible cloud-native API gateway. 
    {{site.base_gateway}} sits in front of your upstream services, dynamically controlling, analyzing, and 
    routing requests and responses. {{site.base_gateway}} implements your API traffic policies 
    by using a flexible, low-code, plugin-based approach. 
    <br><br>
    This tutorial will help you get started with {{site.base_gateway}} by setting up either a {{site.konnect_short_name}} hybrid deployment or 
    self-managed local installation and walking through some common API management tasks. 

    {:.info}
    > **Note:**
    > This quickstart runs a Docker container to explore {{ site.base_gateway }}'s capabilities. 
    If you want to run {{ site.base_gateway }} as a part of a production-ready API platform, start with the [Install](/gateway/install/) page.

tools:
    - deck
  
prereqs:
  inline:
    - title: cURL
      content: |
        [cURL](https://curl.se/) is used to send requests to {{site.base_gateway}}. 
        `curl` is pre-installed on most systems.

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

min_version:
    gateway: '3.4'
next_steps:
  - text: See all {{site.base_gateway}} tutorials
    url: /how-to/?products=gateway
  - text: Learn about {{site.base_gateway}} entities
    url: /gateway/entities/
  - text: Learn about how {{site.base_gateway}} is configured
    url: /gateway/configuration/
  - text: See all {{site.base_gateway}} plugins
    url: /plugins/
automated_tests: false
---

## Check that {{site.base_gateway}} is running

{% include how-tos/steps/ping-gateway.md %}

## Create a Gateway Service

{{site.base_gateway}} administrators work with an object model to define their
desired traffic management policies. Two important objects in that model are 
[Gateway Services](/gateway/entities/service/) and 
[Routes](/gateway/entities/route/). Together, 
Services and Routes define the path that requests and responses will take 
through the system.

Run the following command to create a Service mapped to the upstream URL `https://httpbin.konghq.com`:

{% entity_examples %}
entities:
  services:
    - name: example_service
      url: "https://httpbin.konghq.com"
{% endentity_examples %}

In this example, you are configuring the following attributes:

* `name`: The name of the Service
* `url` : An attribute that populates the `host`, `port`, and `path` of the Service

## Create a Route 

Routes define how requests are proxied by {{site.base_gateway}}. You can
create a Route associated with a specific Service by sending a `POST`
request to the URL defined in the Service.

Configure a new Route on the `/mock` path to direct traffic to the `example_service` Service:

{% entity_examples %}
entities:
  routes:
    - name: example_route
      service:
        name: example_service
      paths:
        - /mock
{% endentity_examples %}

### Validate the Gateway Service and Route by proxying a request

Using the Service and Route, you can now 
access `https://httpbin.konghq.com/` using the `/mock` path.

Httpbin provides an `/anything` resource which will return information about requests made to it.
Proxy a request through {{site.base_gateway}} to the `/anything` resource:

{% validation request-check %}
url: /mock/anything
status_code: 200
{% endvalidation %}

You should get a `200` response back.

## Enable authentication

Authentication is the process of verifying that the requester has permissions to access a resource. 
As its name implies, API gateway authentication authenticates the flow of data to and from your upstream services. 

### Enable Key Auth plugin

The [Key Authentication plugin](/plugins/key-auth/) lets you secure requests to your services with API keys. Use this plugin when you want to verify that every request comes from a known client.

When activated, {{site.base_gateway}} generates and associates an API key with a [Consumer](/gateway/entities/consumer/). The client then presents this key as a secret in subsequent requests. Each request is approved or denied based on the validity of the key. The configuration uses the following logic:
- The `key_names` field defines the request field the plugin checks for a key.
- The plugin searches for this field in headers, query string parameters, and the request body.

After setup, only requests that include a valid API key are accepted. To activate the Key Authentication plugin, copy and run the following command:

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key_names:
          - apikey
{% endentity_examples %}

### Create a Consumer

Consumers let you identify the client that's interacting with {{site.base_gateway}}. You need to create a Consumer for key authentication to work.

Create a new Consumer with the username `luka` and the key `top-secret-key`:

{% entity_examples %}
entities:
  consumers:
    - username: luka
      keyauth_credentials:
        - key: top-secret-key
{% endentity_examples %}

{:.warning}
> For the purposes of this tutorial, we have assigned an example key value. 
In production, it is recommended that you let the API gateway autogenerate a complex key for you. 
Only specify a key for testing or when migrating existing systems.

### Validate using key authentication

Try to access the Service without providing the key:

{% validation unauthorized-check %}
url: /mock/anything
message: No API key found in request
{% endvalidation %}

Since you enabled key authentication globally, you will receive an unauthorized response:

```text
HTTP/1.1 401 Unauthorized
...
{
    "message": "No API key found in request"
}
```
{:.no-copy-code}

Now, let's send a request with the valid key in the `apikey` header:

{% validation request-check %}
url: /mock/anything
display_headers: true
headers:
  - 'apikey:top-secret-key'
status_code: 200
{% endvalidation %}

You will receive a `200 OK` response.

## Enable load balancing

Load balancing is a method of distributing API request traffic across
multiple upstream services. Load balancing improves overall system responsiveness
and reduces failures by preventing overloading of individual resources. 

In the following example, you’ll use an application deployed across two different hosts, or upstream targets. 
{{site.base_gateway}} needs to load balance across the upstreams, so that if one of them is unavailable, 
it automatically detects the problem and routes all traffic to the working upstream.

You'll need to configure two new types of entities: an [Upstream](/gateway/entities/upstream/) and two [Targets](/gateway/entities/target/). Create an Upstream named `example_upstream` and add two Targets to it:

{% entity_examples %}
entities:
  upstreams:
    - name: example_upstream
      targets:
        - target: httpbun.com:80
          weight: 100
        - target: httpbin.konghq.com:80
          weight: 100
{% endentity_examples %}

Let's update the `example_service` Service to point to this Upstream, instead of pointing directly to a URL:
  
{% entity_examples %}
entities:
  services:
    - name: example_service
      host: example_upstream
{% endentity_examples %}

You now have an Upstream with two Targets, `httpbin.konghq.com` and `httpbun.com`, and a Gateway Service pointing to that Upstream.

{:.info}
> For the purposes of our example, the Upstream is pointing to two different Targets. 
More commonly, Targets will be instances of the same upstream service running on different host systems.

### Validate load balancing

Validate that the Upstream you configured is working by visiting the `/mock` route several times, 
waiting a few seconds between each time.
You will see the hostname change between `httpbin` and `httpbun`:

```sh
curl -s http://localhost:8000/mock/headers \
  -H 'apikey:top-secret-key' | grep -i -A1 '"host"'
```
{: data-deployment-topology="on-prem" }

```sh
curl -s $KONNECT_PROXY_URL/mock/headers \
  -H 'apikey:top-secret-key' | grep -i -A1 '"host"'
```
{: data-deployment-topology="konnect" }

## Enable caching

Caching is used to store and reuse upstream responses for faster replies and less backend load. The [Proxy Cache plugin](/plugins/proxy-cache/) accelerates performance by caching responses based on configurable response codes, content types, and request methods.
When caching is enabled, upstream services are not bogged down with repetitive requests,
because {{site.base_gateway}} responds on their behalf with cached results.

Let's enable the Proxy Cache plugin globally:

{% entity_examples %}
entities:
  plugins:
    - name: proxy-cache
      config:
        request_method: 
          - GET
        response_code: 
          - 200
        content_type: 
          - application/json
        cache_ttl: 30
        strategy: memory
{% endentity_examples %}

This configures a Proxy Cache plugin with the following attributes:
* {{site.base_gateway}} will cache all `GET` requests that result in response codes of `200`
* It will also cache responses with the `Content-Type` headers that *equal* `application/json`
* `cache_ttl` instructs the plugin to flush values after 30 seconds
* `config.strategy=memory` specifies the backing data store for cached responses. More
information on `strategy` can be found in the [parameter reference](/plugins/proxy-cache/reference/)
for the Proxy Cache plugin.

### Validate caching

You can check that the Proxy Cache plugin is working by sending `GET` requests and examining
the returned headers.

Run the following command to send 2 mock requests. 
The Proxy Cache plugin returns status information headers prefixed with `X-Cache`, so you can use `grep` to filter for that information:

```sh
for _ in {1..2}; do \
  curl -s -i http://localhost:8000/mock/anything \
    -H 'apikey:top-secret-key'; \
  echo; sleep 1; \
done | grep -E 'X-Cache'
```
{: data-deployment-topology="on-prem" }

```sh
for _ in {1..2}; do \
  curl -s -i $KONNECT_PROXY_URL/mock/anything \
    -H 'apikey:top-secret-key'; \
  echo; sleep 1; \
done | grep -E 'X-Cache'
```
{: data-deployment-topology="konnect" }

On the initial request, there should be no cached responses, and the headers will indicate this with
`X-Cache-Status: Miss`:

```
X-Cache-Key: c9e1d4c8e5fd8209a5969eb3b0e85bc6
X-Cache-Status: Miss
```
{:.no-copy-code}

The following response will be cached and show `X-Cache-Status: Hit`:

```
X-Cache-Key: c9e1d4c8e5fd8209a5969eb3b0e85bc6
X-Cache-Status: Hit
```
{:.no-copy-code}

## Enable rate limiting

[Rate limiting](/rate-limiting/) is used to control the rate of requests sent to an upstream service. 
It can be used to prevent DoS attacks, limit web scraping, and other forms of overuse. 
Without rate limiting, clients have unlimited access to your upstream services, which
may negatively impact availability.

In this example, we'll use the [Rate Limiting plugin](/plugins/rate-limiting/).
Installing the plugin globally means that *every* proxy request to {{site.base_gateway}}
will be subject to rate limit enforcement:

{% entity_examples %}
entities:
  plugins:
    - name: rate-limiting
      config:
        minute: 5
        policy: local
{% endentity_examples %}

In this example, you configured a limit of 5 requests per minute for all Routes, Services, and Consumers.

### Validate rate limiting 

You can check that the Rate Limiting plugin is working by sending `GET` requests and examining
the returned headers.

Run the following command to send 6 mock requests:

{% validation rate-limit-check %}
iterations: 6
url: '/mock/anything'
headers:
  - 'apikey:top-secret-key'
{% endvalidation %}

After the 6th request, you should receive a 429 error, which means your requests were rate limited according to the policy:
```
HTTP/1.1 429 Too Many Requests
```
{:.no-copy-code}
