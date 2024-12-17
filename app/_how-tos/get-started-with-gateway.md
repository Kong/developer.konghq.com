---
title: Get started with {{site.base_gateway}}
content_type: how_to

products:
    - gateway

works_on:
    - on-prem
    - konnect

plugins:
  - rate-limiting
  - key-auths
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
  q: What is Kong Gateway, and how can I get started with it?
  a: |
    [{{site.base_gateway}}](/gateway/) is a lightweight, fast, and flexible cloud-native API gateway. 
    {{site.base_gateway}} sits in front of your service applications, dynamically controlling, analyzing, and 
    routing requests and responses. {{site.base_gateway}} implements your API traffic policies 
    by using a flexible, low-code, plugin-based approach. 
    <br><br>
    This tutorial will help you get started with {{site.base_gateway}} by setting up a local installation
    and walking through some common API management tasks. 

    {:.info}
    > **Note:**
    > This quickstart runs a simple Docker container to explore {{ site.base_gateway }}'s capabilities. 
    If you want to run {{ site.base_gateway }} as a part of a production-ready API platform, start on the [Install](/gateway/install/) page.
tools:
    - deck
  
prereqs:
  inline:
    - title: cURL
      content: |
        [cURL](https://curl.se/) is used to send requests to {{site.base_gateway}}. `curl` is pre-installed on most systems
      icon_url: /assets/icons/code.svg

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## 1. Check that Kong Gateway is running

{{site.base_gateway}} serves an Admin API on the default port `8001`. The Admin API can be used for
both querying and controlling the state of {{site.base_gateway}}. The following command
will query the Admin API, fetching the headers only:

```sh
curl --head localhost:8001
```

If {{site.base_gateway}} is running properly, it will respond with a `200` HTTP code.

## 2. Create a Service

{{site.base_gateway}} administrators work with an object model to define their
desired traffic management policies. Two important objects in that model are 
[Services](/gateway/entities/service/) and 
[Routes](/gateway/entities/route/). Together, 
Services and Routes define the routing path that requests and responses will take 
through the system.

Add the following content to `kong.yaml` to create a 
Service mapped to the upstream URL `https://httpbin.konghq.com`:

{% entity_examples %}
entities:
  services:
    - name: example_service
      url: "https://httpbin.konghq.com"
{% endentity_examples %}

In this example, you are configuring the following attributes:

* `name`: The name of the Service
* `url` : An argument that populates the `host`, `port`, and `path` attributes of the Service

## 3. Create a Route 

Routes define how requests are proxied by {{site.base_gateway}}. You can
create a Route associated with a specific Service by sending a `POST`
request to the Service URL.

Configure a new Route on the `/mock` path to direct traffic to the `example_service` Service:

{% entity_examples %}
entities:
  routes:
    - name: example_route
      service: example_service
      paths:
        - /mock
{% endentity_examples %}

### Apply configuration

{% include how-tos/steps/apply_config.md %}

### Validate the Service and Route by proxying a request

Using the Service and Route, you can now 
access `https://httpbin.konghq.com/` using `http://localhost:8000/mock`.

By default, {{site.base_gateway}}'s Admin API listens for administrative requests on port `8001`.

Httpbin provides an `/anything` resource which will echo back to clients information about requests made to it.
Proxy a request through {{site.base_gateway}} to the `/anything` resource:

```sh
curl -X GET http://localhost:8000/mock/anything
```

## 4. Enable rate limiting

[Rate limiting](/rate-limiting/) is used to control the rate of requests sent to an upstream Service. 
It can be used to prevent DoS attacks, limit web scraping, and other forms of overuse. 
Without rate limiting, clients have unlimited access to your upstream Services, which
may negatively impact availability.

In this example, we'll use the [Rate Limiting plugin](/plugins/rate-limiting/).
Let's install the plugin globally, which means that *every* proxy request to {{site.base_gateway}}
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

After configuring rate limiting, you can verify that it was configured correctly and is working 
by sending more requests than allowed in the configured time limit.

[Sync your decK](#apply-configuration) file again, then run the following command to quickly send 6 mock requests:

```sh
for _ in {1..6}; do curl -s -i localhost:8000/mock/anything; echo; sleep 1; done
```

After the 6th request, you should receive a 429 "API rate limit exceeded" error:
```
{
    "message": "API rate limit exceeded"
}
```

## 4. Enable proxy caching 

One of the ways Kong delivers performance is through caching.
The [Proxy Cache plugin](/plugins/proxy-cache/) accelerates performance by caching
responses based on configurable response codes, content types, and request methods.
When caching is enabled, upstream Services are not bogged down with repetitive requests,
because {{site.base_gateway}} responds on their behalf with cached results.

Let's enable the Proxy Cache plugin globally:

{% entity_examples %}
entities:
  plugins:
    - name: proxy-cache
      config:
        request_method: GET
        response_code: 200
        content_type: application/json
        cache_ttl: 30
        strategy: memory
append_to_existing_section: true
{% endentity_examples %}

This configures a Proxy Cache plugin with the following attributes:
* {{site.base_gateway}} will cache all `GET` requests that result in response codes of `200`
* It will also cache responses with the `Content-Type` headers that *equal* `application/json`
* `cache_ttl` instructs the plugin to flush values after 30 seconds
* `config.strategy=memory` specifies the backing data store for cached responses. More
information on `strategy` can be found in the [parameter reference](/plugins/proxy-cache/reference/)
for the Proxy Cache plugin.

### Validate proxy caching

You can check that the Proxy Cache plugin is working by sending `GET` requests and examining
the returned headers.

[Sync your decK](#apply-configuration) file, then make an initial request to the `/mock` Route. 
The Proxy Cache plugin returns status
information headers prefixed with `X-Cache`, so you can use `grep` to filter for that information:

```
curl -i -s -XGET http://localhost:8000/mock/anything | grep X-Cache
```

On the initial request, there should be no cached responses, and the headers will indicate this with
`X-Cache-Status: Miss`.

```
X-Cache-Key: c9e1d4c8e5fd8209a5969eb3b0e85bc6
X-Cache-Status: Miss
```

Within 30 seconds of the initial request, repeat the command to send an identical request and the
headers will indicate a cache `Hit`:

```
X-Cache-Key: c9e1d4c8e5fd8209a5969eb3b0e85bc6
X-Cache-Status: Hit
```

## 5. Enable key authentication

Authentication is the process of verifying that a requester has permissions to access a resource. 
As its name implies, API gateway authentication authenticates the flow of data to and from your upstream services. 

### Enable Key Auth plugin

For this example, we'll use the [Key Authentication plugin](/plugins/key-auth/). In key authentication, 
{{site.base_gateway}} generates and associates an API key with a [Consumer](/gateway/entities/consumer/). 
That key is the authentication secret presented by the client when making subsequent requests. 
{{site.base_gateway}} approves or denies requests based on the validity of the presented key.

{% entity_examples %}
entities:
  plugins:
    - name: key-auth
      config:
        key-names:
          - api-key
append_to_existing_section: true
{% endentity_examples %}

The `key_names` configuration field defines the name of the field that the
plugin looks for to read the key when authenticating requests. 
The plugin looks for the field in headers, query string parameters, and the request body.

### Create a Consumer

Consumers let you identify the client that's interacting with {{site.base_gateway}}, so you need a Consumer for key authentication to work.

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

### Validate key authentication

[Sync your decK](#apply-configuration) file, then let's try to access the Service without providing the key:
   
```sh
curl -i http://localhost:8000/mock/anything
```

Since you enabled key authentication globally, you will receive an unauthorized response:

```text
HTTP/1.1 401 Unauthorized
...
{
    "message": "No API key found in request"
}
```

Now, let's send a request with the valid key in the `apikey` header:

```sh
curl -i http://localhost:8000/mock/anything \
  -H 'apikey:top-secret-key'
```

You will receive a `200 OK` response.

## 6. Enable load balancing

Load balancing is a method of distributing API request traffic across
multiple upstream services. Load balancing improves overall system responsiveness
and reduces failures by preventing overloading of individual resources. 

In the following example, you’ll use an application deployed across two different servers, or upstream targets. 
{{site.base_gateway}} needs to load balance across both servers, so that if one of the servers is unavailable, 
it automatically detects the problem and routes all traffic to the working server.

You'll need to configure two new types of entities: an [Upstream](/gateway/entities/upstream/) and two [Targets](/gateway/entities/target/). Create an Upstream named `example_upstream` and add two Targets to it:

{% entity_examples %}
entities:
  upstreams:
    - name: example_upstream
      targets:
        - target: "httpbun.com:80"
        - target: "httpbin.konghq.com:80"
{% endentity_examples %}

Update the `example_service` Service to point to this Upstream, instead of pointing directly to a URL. 
Remove its `url` field and add the Upstream as a host:
  
{% entity_examples %}
entities:
  services:
    - name: example_service
      host: example_upstream
{% endentity_examples %}

You now have an Upstream with two Targets, `httpbin.konghq.com` and `httpbun.com`, and a service pointing to that Upstream.

{:.info}
> For the purposes of our example, the Upstream is pointing to two different Targets. 
More commonly, Targets will be instances of the same backend service running on different host systems.

### Validate load balancing

[Sync your decK](#apply-configuration) file one more time.

Validate that the Upstream you configured is working by visiting the Route 
`http://localhost:8000/mock` using a web browser or CLI. Remember to add your apikey!

* **Web browser**: Visit `http://localhost:8000/mock?apikey=top-secret-key` and refresh the page several times to see the site change from `httpbin` to `httpbun`.
* **CLI**: Execute the command `curl -s http://localhost:8000/mock/headers -H 'apikey:top-secret-key' |grep -i -A1 '"host"'` several times. You will see the hostname change between `httpbin` and `httpbun`.

