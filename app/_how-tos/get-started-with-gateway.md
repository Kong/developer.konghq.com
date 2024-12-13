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
  - key-auth
  - proxy-caching

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

    This tutorial will help you get started with {{site.base_gateway}} by setting up a local installation
    and walking through some common API management tasks. 

tools:
    - deck

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

{:.note}
> **Note:**
> This quickstart runs on your local machine to explore {{ site.base_gateway }}'s capabilities. If you want to run {{ site.base_gateway }} as a part of a production-ready API platform, start on the `/install` page.

<!-- 
* [Understanding and configuring Services and Routes](/gateway/{{ page.release }}/get-started/services-and-routes)
* [Configuring Rate Limiting to protect upstream Services](/gateway/{{ page.release }}/get-started/rate-limiting)
* [Increase system performance with Proxy Caching](/gateway/{{ page.release }}/get-started/proxy-caching)
* [Load Balancing for horizontal Service scaling](/gateway/{{ page.release }}/get-started/load-balancing)
* [Protecting Services with Key Authentication](/gateway/{{ page.release }}/get-started/key-authentication) -->

### Prerequisites

* [Docker](https://docs.docker.com/get-docker/) is used to run {{site.base_gateway}} and supporting database locally
* [curl](https://curl.se/) is used to send requests to {{site.base_gateway}}. `curl` is pre-installed on most systems
* [jq](https://stedolan.github.io/jq/) is used to process JSON responses on the command line. While useful, this tool is 
not necessary to complete the tasks of this tutorial. If you wish to proceed without `jq`, modify the commands to
remove `jq` processing.

## 1. Get Kong

For the purposes of this tutorial, a `quickstart` script is provided to quickly run {{site.base_gateway}} and its supporting database.
This script uses Docker to run {{site.base_gateway}} and a [PostgreSQL](https://www.postgresql.org/) database as the backing database.

1. Verify that {{site.base_gateway}} is running:

   {{site.base_gateway}} serves an Admin API on the default port `8001`. The Admin API can be used for
   both querying and controlling the state of {{site.base_gateway}}. The following command
   will query the Admin API, fetching the headers only:

   ```sh
   curl --head localhost:8001
   ```

   If {{site.base_gateway}} is running properly, it will respond with a `200` HTTP code, similar to the following: 

   ```text
   HTTP/1.1 200 OK
   Date: Mon, 22 Aug 2022 19:25:49 GMT
   Content-Type: application/json
   Connection: keep-alive
   Access-Control-Allow-Origin: *
   Content-Length: 11063
   X-Kong-Admin-Latency: 6
   Server: kong/{{page.versions.ce}}
   ```

1. Evaluate the {{site.base_gateway}} configuration:

   The root route of the Admin API provides important information about the running 
   {{site.base_gateway}} including networking, security, and plugin information. The full 
   configuration is provided in the `.configuration` key of the returned JSON document.

   ```sh
   curl -s localhost:8001 | jq '.configuration'
   ```

   You should receive a large JSON response with {{site.base_gateway}} configuration information.

1. Access Kong Manager
   
    While the rest of this guide demonstrates configuring {{site.base_gateway}} using the Admin API, you can also use Kong Manager to manage your Services, Routes, Plugins, and more. To access Kong Manager, go to the following URL: [http://localhost:8002](http://localhost:8002)

    {:.note}
    > **Note:** If you install {{site.ce_product_name}}, you will use Kong Manager Open Source. All other {{site.base_gateway}} installations use Kong Manager Enterprise.

Every step in this tutorial requires a running {{site.base_gateway}}, so leave
everything running and proceed to the next steps in this tutorial.

## 2. Services and Routes

{{site.base_gateway}} administrators work with an object model to define their
desired traffic management policies. Two important objects in that model are 
[services](/gateway/api/admin-ee/latest/#/Services) and 
[routes](/gateway/api/admin-ee/latest/#/Routes/list-route). Services and routes are configured in a 
coordinated manner to define the routing path that requests and responses will take 
through the system.

### What is a service

In {{site.base_gateway}}, a service is an abstraction of an existing upstream application. 
Services can store collections of objects like plugin configurations, and policies, and they can be 
associated with routes. 

When defining a service, the administrator provides a *name* and the upstream application connection
information. The connection details can be provided in the `url` field as a single string, or by providing
individual values for `protocol`, `host`, `port`, and `path` individually.

Services have a one-to-many relationship with upstream applications, which allows administrators to 
create sophisticated traffic management behaviors. 

### What is a route

A route is a path to a resource within an upstream application. Routes are added to services to allow 
access to the underlying application. In {{site.base_gateway}}, routes typically map to endpoints that are 
exposed through the {{site.base_gateway}} application. Routes can also define rules that match requests to 
associated services. Because of this, one route can reference multiple endpoints. A basic route should have a 
name, path or paths, and reference an existing service. 

You can also configure routes with:
* Protocols: The protocol used to communicate with the upstream application. 
* Hosts: Lists of domains that match a route
* Methods: HTTP methods that match a route
* Headers: Lists of values that are expected in the header of a request
* Redirect status codes: HTTPS status codes
* Tags: Optional set of strings to group routes with 

See [Routes](/gateway/{{page.release}}/key-concepts/routes/) for a description of how
{{site.base_gateway}} routes requests. 

### 2. Managing services and routes

The following tutorial walks through managing and testing services and routes using the 
{{site.base_gateway}} [Admin API](/gateway/latest/admin-api/). {{site.base_gateway}} 
also offers other options for configuration management including
[{{site.konnect_saas}}](/konnect/) and [decK](/deck/latest/).

In this section of the tutorial, you will complete the following steps:
* Create a service pointing to the [httpbin](https://httpbin.konghq.com/) API, which provides testing facilities 
  for HTTP requests and responses.
* Define a route by providing a URL path that will be available to clients on the running {{site.base_gateway}}.
* Use the new httpbin service to echo a test request, helping you understand how 
  {{site.base_gateway}} proxies API requests. 

1. **Creating services**

   To add a new service, send a `POST` request to {{site.base_gateway}}'s 
   Admin API `/services` route:

   ```sh
   curl -i -s -X POST http://localhost:8001/services \
     --data name=example_service \
     --data url='https://httpbin.konghq.com'
   ```

   This request instructs {{site.base_gateway}} to create a new 
   service mapped to the upstream URL `https://httpbin.konghq.com`.
   
   In our example, the request body contained two strings: 
   
   * `name`: The name of the service
   * `url` : An argument that populates the `host`, `port`, and `path` attributes of the service
   
   If your request was successful, you will see a `201` response header from {{site.base_gateway}} 
   confirming that your service was created and the response body will be similar to:

   ```text
   {
     "host": "httpbin.konghq.com",
     "name": "example_service",
     "enabled": true,
     "connect_timeout": 60000,
     "read_timeout": 60000,
     "retries": 5,
     "protocol": "http",
     "path": null,
     "port": 80,
     "tags": null,
     "client_certificate": null,
     "tls_verify": null,
     "created_at": 1661346938,
     "updated_at": 1661346938,
     "tls_verify_depth": null,
     "id": "3b2be74e-335b-4f25-9f08-6c41b4720315",
     "write_timeout": 60000,
     "ca_certificates": null
   }
   ```
   
   Fields that are not explicitly provided in the create request are automatically given 
   a default value based on the current {{site.base_gateway}} configuration.  

1. **Viewing service configuration**

   When you create a service, {{site.base_gateway}} assigns it a unique `id` as shown in the response above. 
   The `id` field, or the name provided when creating the service, can be used to identify the service 
   in subsequent requests. This is the service URL and takes the form of `/services/{service name or id}`.

   To view the current state of a service, make a `GET` request to the service
   URL.

   ```sh
   curl -X GET http://localhost:8001/services/example_service
   ```
  
   A successful request will contain the current configuration of your service in the response
   body and will look something like the following snippet:
   
   ```text
   {
     "host": "httpbin.konghq.com",
     "name": "example_service",
     "enabled": true,
     ...
   }
   ```
1. **Updating services**

   Existing service configurations can be updated dynamically by sending a `PATCH`
   request to the service URL. 

   To dynamically set the service retries from `5` to `6`, send this `PATCH` request:

   ```sh
   curl --request PATCH \
     --url localhost:8001/services/example_service \
     --data retries=6
   ```
   
   The response body contains the full service configuration including the updated value:
   
   ```sh
   {
     "host": "httpbin.konghq.com",
     "name": "example_service",
     "enabled": true,
     "retries": 6,
     ...
   }
   ```

1. **Listing services**

   You can list all current services by sending a `GET` request to the base `/services` URL.

   ```sh
   curl -X GET http://localhost:8001/services
   ```

The [Admin API documentation](/gateway/latest/admin-api/#update-service) provides
the full service update specification. 

You can also view the configuration for your services in the Kong Manager UI by navigating to the following URL in your browser: 
* Kong Manager OSS: [http://localhost:8002/services](http://localhost:8002/services) 
* Kong Manager Enterprise: [http://localhost:8002/default/services](http://localhost:8002/default/services), where `default` is the workspace name.
   
### Managing routes

1. **Creating routes**

   Routes define how requests are proxied by {{site.base_gateway}}. You can
   create a route associated with a specific service by sending a `POST`
   request to the service URL.

   Configure a new route on the `/mock` path to direct traffic to the `example_service` service
   created earlier:

   ```sh
   curl -i -X POST http://localhost:8001/services/example_service/routes \
     --data 'paths[]=/mock' \
     --data name=example_route
   ```

   If the route was successfully created, the API returns a `201` response code and a response body like this:
   
   ```text
   {
     "paths": [
       "/mock"
     ],
     "methods": null,
     "sources": null,
     "destinations": null,
     "name": "example_route",
     "headers": null,
     "hosts": null,
     "preserve_host": false,
     "regex_priority": 0,
     "snis": null,
     "https_redirect_status_code": 426,
     "tags": null,
     "protocols": [
       "http",
       "https"
     ],
     "path_handling": "v0",
     "id": "52d58293-ae25-4c69-acc8-6dd729718a61",
     "updated_at": 1661345592,
     "service": {
       "id": "c1e98b2b-6e77-476c-82ca-a5f1fb877e07"
     },
     "response_buffering": true,
     "strip_path": true,
     "request_buffering": true,
     "created_at": 1661345592
   }
   ```

1. **Viewing route configuration**

   Like services, when you create a route, {{site.base_gateway}} 
   assigns it a unique `id` as shown in the response above. The `id` field, or the name provided
   when creating the route, can be used to identify the route in subsequent requests.
   The route URL can take either of the following forms:
   
   * `/services/{service name or id}/routes/{route name or id}`
   * `/routes/{route name or id}`

   To view the current state of the `example_route` route, make a `GET` request to the route URL:

   ```sh
   curl -X GET http://localhost:8001/services/example_service/routes/example_route
   ``` 

   The response body contains the current configuration of your route:

   ```text
   {
     "paths": [
       "/mock"
     ],
     "methods": null,
     "sources": null,
     "destinations": null,
     "name": "example_route",
     "headers": null,
     "hosts": null,
     "preserve_host": false,
     "regex_priority": 0,
     "snis": null,
     "https_redirect_status_code": 426,
     "tags": null,
     "protocols": [
       "http",
       "https"
     ],
     "path_handling": "v0",
     "id": "189e0a57-205a-4f48-aec6-d57f2e8a9985",
     "updated_at": 1661347991,
     "service": {
       "id": "3b2be74e-335b-4f25-9f08-6c41b4720315"
     },
     "response_buffering": true,
     "strip_path": true,
     "request_buffering": true,
     "created_at": 1661347991
   }
   ```

1. **Updating routes**

   Like services, routes can be updated dynamically by sending a `PATCH`
   request to the route URL. 
   
   Tags are an optional set of strings that can be associated with the route for grouping and filtering. 
   You can assign tags by sending a `PATCH` request to the 
   [services endpoint](/gateway/latest/admin-api/#update-route) and specifying a route.

   Update the route by assigning it a tag with the value `tutorial`:
   
   ```
   curl --request PATCH \
     --url localhost:8001/services/example_service/routes/example_route \
     --data tags="tutorial"
   ```
   
   The above example used the service and route `name` fields for the route URL.
   
   If the tag was successfully applied, the response body will contain the following JSON value: 
   
   ```text
   ...
   "tags":["tutorial"]
   ...
   ```

1. **Listing routes**

   The Admin API also supports the listing of all routes currently configured:

   ```sh
   curl http://localhost:8001/routes
   ```

   This request returns an HTTP `200` status code and a JSON response body object array with all of 
   the routes configured on this {{site.base_gateway}} instance. Your response should look like the following:

   ```text
   {
     "next": null,
     "data": [
       {
         "paths": [
           "/mock"
         ],
         "methods": null,
         "sources": null,
         "destinations": null,
         "name": "example_route",
         "headers": null,
         "hosts": null,
         "preserve_host": false,
         "regex_priority": 0,
         "snis": null,
         "https_redirect_status_code": 426,
         "tags": [
           "tutorial"
         ],
         "protocols": [
           "http",
           "https"
         ],
         "path_handling": "v0",
         "id": "52d58293-ae25-4c69-acc8-6dd729718a61",
         "updated_at": 1661346132,
         "service": {
           "id": "c1e98b2b-6e77-476c-82ca-a5f1fb877e07"
         },
         "response_buffering": true,
         "strip_path": true,
         "request_buffering": true,
         "created_at": 1661345592
       }
     ]
   }
   ```

The [Admin API documentation](/gateway/api/admin-ee/latest/#/Routes/list-route/) has the 
full specification for managing route objects.

You can also view the configuration for your routes in the Kong Manager UI by navigating to the following URL in your browser: [http://localhost:8002/default/routes](http://localhost:8002/default/routes)

### Proxy a request 

Kong is an API Gateway, it takes requests from clients and routes them to the appropriate upstream application 
based on a the current configuration. Using the service and route that was previously configured, you can now 
access `https://httpbin.konghq.com/` using `http://localhost:8000/mock`.

By default, {{site.base_gateway}}'s Admin API listens for administrative requests on port `8001`, this is sometimes referred to as the
*control plane*. Clients use port `8000` to make data requests, and this is often referred to as the *data plane*.

Httpbin provides an `/anything` resource which will echo back to clients information about requests made to it.
Proxy a request through {{site.base_gateway}} to the `/anything` resource:

```sh
curl -X GET http://localhost:8000/mock/anything
```

You should see a response similar to the following:
```text
{
  "startedDateTime": "2022-08-24T13:44:28.449Z",
  "clientIPAddress": "172.19.0.1",
  "method": "GET",
  "url": "http://localhost/anything",
  "httpVersion": "HTTP/1.1",
  "cookies": {},
  "headers": {
    "host": "httpbin.konghq.com",
    "connection": "close",
    "accept-encoding": "gzip",
    "x-forwarded-for": "172.19.0.1,98.63.188.11, 162.158.63.41",
    "cf-ray": "73fc85d999f2e6b0-EWR",
    "x-forwarded-proto": "http",
    "cf-visitor": "{\"scheme\":\"http\"}",
    "x-forwarded-host": "localhost",
    "x-forwarded-port": "80",
    "x-forwarded-path": "/mock/anything",
    "x-forwarded-prefix": "/mock",
    "user-agent": "curl/7.79.1",
    "accept": "*/*",
    "cf-connecting-ip": "00.00.00.00",
    "cdn-loop": "cloudflare",
    "x-request-id": "1dae4762-5d7f-4d7b-af45-b05720762878",
    "via": "1.1 vegur",
    "connect-time": "0",
    "x-request-start": "1661348668447",
    "total-route-time": "0"
  },
  "queryString": {},
  "postData": {
    "mimeType": "application/octet-stream",
    "text": "",
    "params": []
  },
  "headersSize": 588,
  "bodySize": 0
}
```

## 3. Rate Limiting

Rate limiting is used to control the rate of requests sent to an upstream service. 
It can be used to prevent DoS attacks, limit web scraping, and other forms of overuse. 
Without rate limiting, clients have unlimited access to your upstream services, which
may negatively impact availability.

### The Rate Limiting plugin

{{site.base_gateway}} imposes rate limits on clients through the use of the [Rate Limiting plugin](/hub/kong-inc/rate-limiting/). 
When rate limiting is enabled, clients are restricted in the number of requests that can be made in a configurable period of time.
The plugin supports identifying clients as [consumers](/gateway/api/admin-ee/latest/#/Consumers/list-consumer/) 
or by the client IP address of the requests.

{:.note}
> This tutorial uses the [Rate Limiting](/hub/kong-inc/rate-limiting/) <span class="badge free"></span> plugin. Also available is the 
[Rate Limiting Advanced](/hub/kong-inc/rate-limiting-advanced) <span class="badge enterprise"></span> 
plugin. The advanced version provides additional features like support for the sliding window algorithm
and advanced Redis support for greater performance.

### Global rate limiting 

Installing the plugin globally means *every* proxy request to {{site.base_gateway}}
will be subject to rate limit enforcement.

1. **Enable rate limiting**

   The rate limiting plugin is installed by default on {{site.base_gateway}}, and can be enabled
   by sending a `POST` request to the [plugins](/gateway/latest/admin-api/#add-plugin) object on the Admin API: 
   
   ```sh
   curl -i -X POST http://localhost:8001/plugins \
     --data name=rate-limiting \
     --data config.minute=5 \
     --data config.policy=local
   ```

   This command has instructed {{site.base_gateway}} to impose a maximum of 5 requests per minute per client IP address
   for all routes and services.

   The `policy` configuration determines where {{site.base_gateway}} retrieves and increments limits. See the full
   [plugin configuration reference](/hub/kong-inc/rate-limiting/#configuration) for details.
   
   You will see a response that contains the new plugin configuration, including identification information similar to:

   ```text
   ...
   "id": "fc559a2d-ac80-4be8-8e43-cb705524be7f",
   "name": "rate-limiting",
   "enabled": true
   ...
   ```

1. **Validate**

   After configuring rate limiting, you can verify that it was configured correctly and is working, 
   by sending more requests than allowed in the configured time limit.

    Run the following command to quickly send 6 mock requests:

    ```sh
    for _ in {1..6}; do curl -s -i localhost:8000/mock/anything; echo; sleep 1; done
    ```

    After the 6th request, you should receive a 429 "API rate limit exceeded" error:
    ```
    {
        "message": "API rate limit exceeded"
    }
    ```

### Advanced rate limiting

In high scale production scenarios, effective rate limiting may require
advanced techniques. The basic Rate Limiting plugin described above 
only allows you to define limits over fixed-time windows. Fixed-time windows
are sufficient for many cases, however, there are disadvantages:
* Bursts of requests around the boundary time of the fixed window,
may result in strained resources as the window counter is reset in the middle
of the traffic burst. 
* Multiple client applications may be waiting for the fixed-time window to reset 
so they can resume making requests. When the fixed-window resets, multiple clients
may flood the system with requests, causing a stampeding effect on your upstream services.

The [Rate Limiting Advanced](/hub/kong-inc/rate-limiting-advanced/) <span class="badge enterprise"></span> 
plugin is an enhanced version of the Rate Limiting plugin. The advanced plugin 
provides additional limiting algorithm capabilities and superior performance compared
to the basic plugin. For more information on advanced rate limiting algorithms, see 
[How to Design a Scalable Rate Limiting Algorithm with Kong API](https://konghq.com/blog/how-to-design-a-scalable-rate-limiting-algorithm).


## 4. Proxy caching 

One of the ways Kong delivers performance is through caching.
The [Proxy Cache plugin](/hub/kong-inc/proxy-cache/) accelerates performance by caching
responses based on configurable response codes, content types, and request methods.
When caching is enabled, upstream services are not bogged down with repetitive requests,
because {{site.base_gateway}} responds on their behalf with cached results. Caching can be
enabled on specific {{site.base_gateway}} objects or for all requests globally.

### Cache Time To Live (TTL)

TTL governs the refresh rate of cached content, which is critical for ensuring
that clients aren't served outdated content. A TTL of 30 seconds means content older than
30 seconds is deemed expired and will be refreshed on subsequent requests.
TTL configurations should be set differently based on the type of the content the upstream
service is serving.

* Static data that is rarely updated can have longer TTL

* Dynamic data should use shorter TTL to avoid serving outdated data  

{{site.base_gateway}} follows [RFC-7234 section 5.2](https://tools.ietf.org/html/rfc7234)
for cached controlled operations. See the specification and the Proxy Cache
plugin [parameter reference](/hub/kong-inc/proxy-cache/#parameters) for more details on TTL configurations.

### Enable caching

The following tutorial walks through managing proxy caching across various aspects in {{site.base_gateway}}.

### Global proxy caching

Installing the plugin globally means *every* proxy request to {{site.base_gateway}}
will potentially be cached.

1. **Enable proxy caching**

   The Proxy Cache plugin is installed by default on {{site.base_gateway}}, and can be enabled by
   sending a `POST` request to the plugins object on the Admin API:

   ```sh
   curl -i -X POST http://localhost:8001/plugins \
     --data "name=proxy-cache" \
     --data "config.request_method=GET" \
     --data "config.response_code=200" \
     --data "config.content_type=application/json" \
     --data "config.cache_ttl=30" \
     --data "config.strategy=memory"
   ```

   If configuration was successful, you will receive a `201` response code.

   This Admin API request configured a Proxy Cache plugin for all `GET` requests that resulted
   in response codes of `200` and *response* `Content-Type` headers that *equal*
   `application/json`. `cache_ttl` instructed the plugin to flush values after 30 seconds.

   The final option `config.strategy=memory` specifies the backing data store for cached responses. More
   information on `strategy` can be found in the [parameter reference](/hub/kong-inc/proxy-cache/)
   for the Proxy Cache plugin.

1. **Validate**

   You can check that the Proxy Cache plugin is working by sending `GET` requests and examining
   the returned headers. In step two of this guide, [services and routes](/gateway/latest/get-started/services-and-routes/),
   you setup a `/mock` route and service that can help you see proxy caching in action.

   First, make an initial request to the `/mock` route. The Proxy Cache plugin returns status
   information headers prefixed with `X-Cache`, so use `grep` to filter for that information:

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

   The `X-Cache-Status` headers can return the following cache results:

   |State| Description                                                                                                                                          |
   |---|------------------------------------------------------------------------------------------------------------------------------------------------------|
   |Miss| The request could be satisfied in cache, but an entry for the resource was not found in cache, and the request was proxied upstream.                 |
   |Hit| The request was satisfied. The resource was found in cache.                                                                                            |
   |Refresh| The resource was found in cache, but could not satisfy the request, due to Cache-Control behaviors or reaching its hard-coded `cache_ttl` threshold. |
   |Bypass| The request could not be satisfied from cache based on plugin configuration.                                                                         |

### Manage cached entities

The Proxy Cache plugin supports administrative endpoints to manage cached entities. Administrators can
view and delete cached entities, or purge the entire cache by sending requests to the Admin API.

To retrieve the cached entity, submit a request to the Admin API `/proxy-cache` endpoint with the
`X-Cache-Key` value of a known cached value. This request must be submitted prior to the TTL expiration,
otherwise the cached entity has been purged.

For example, using the response headers above, pass the `X-Cache-Key` value of
`c9e1d4c8e5fd8209a5969eb3b0e85bc6` to the Admin API:

```sh
curl -i http://localhost:8001/proxy-cache/c9e1d4c8e5fd8209a5969eb3b0e85bc6
```

A response with `200 OK` will contain full details of the cached entity.

See the [Proxy Cache plugin documentation](/hub/kong-inc/proxy-cache/#admin-api) for the full list of the
Proxy Cache specific Admin API endpoints.


## 5. Authentication

Authentication is the process of verifying that a requester has permissions to access a resource. 
As its name implies, API gateway authentication authenticates the flow of data to and from your upstream services. 

{{site.base_gateway}} has a library of plugins that support 
the most widely used [methods of API gateway authentication](/hub/#authentication). 

Common authentication methods include:
* Key Authentication
* Basic Authentication
* OAuth 2.0 Authentication
* LDAP Authentication Advanced
* OpenID Connect

With {{site.base_gateway}} controlling authentication, requests won't reach upstream services unless the client has successfully
authenticated. This means upstream services process pre-authorized requests, freeing them from the 
cost of authentication, which reduces computing time *and* development effort.

{{site.base_gateway}} has visibility into all authentication attempts, which provides the ability to build 
monitoring and alerting capabilities supporting service availability and compliance. 

For more information, see [What is API Gateway Authentication?](https://konghq.com/learning-center/api-gateway/api-gateway-authentication).

### Enable authentication

The following tutorial walks through how to enable the [Key Authentication plugin](/hub/kong-inc/key-auth/) across
various aspects in {{site.base_gateway}}.

API key authentication is a popular method for enforcing API authentication. In key authentication, 
{{site.base_gateway}} is used to generate and associate an API key with a [consumer](/gateway/api/admin-ee/latest/#/Consumers/list-consumer/). 
That key is the authentication secret presented by the client when making subsequent requests. {{site.base_gateway}} approves or 
denies requests based on the validity of the presented key. This process can be applied globally or to individual 
[services](/gateway/latest/key-concepts/services/) and [routes](/gateway/latest/key-concepts/routes/).

### Set up consumers and keys 

Key authentication in {{site.base_gateway}} works by using the consumer object. Keys are assigned to 
consumers, and client applications present the key within the requests they make.

1. **Create a new consumer**

   For the purposes of this tutorial, create a new consumer with a username `luka`:

   ```sh
   curl -i -X POST http://localhost:8001/consumers/ \
     --data username=luka
   ```

   You will receive a `201` response indicating the consumer was created.

1. **Assign the consumer a key**

   Once provisioned, call the Admin API to assign a key for the new consumer.
   For this tutorial, set the key value to `top-secret-key`:

   ```sh
   curl -i -X POST http://localhost:8001/consumers/luka/key-auth \
     --data key=top-secret-key
   ```

   You will receive a `201` response indicating the key was created.

   In this example, you have explicitly set the key contents to `top-secret-key`.
   If you do not provide the `key` field, {{site.base_gateway}} will generate the key value for you.

   {:.important}
   > **Warning**: For the purposes of this tutorial, we have assigned an example key value. It is recommended that you let the 
   API gateway autogenerate a complex key for you. Only specify a key for testing or when migrating existing systems.
   

### Global key authentication 

Installing the plugin globally means *every* proxy request to {{site.base_gateway}} is protected by key authentication.

1. **Enable key authentication**

   The Key Authentication plugin is installed by default on {{site.base_gateway}} and can be enabled
   by sending a `POST` request to the plugins object on the Admin API:

   ```sh
   curl -X POST http://localhost:8001/plugins/ \
       --data "name=key-auth"  \
       --data "config.key_names=apikey"
   ```

   You will receive a `201` response indicating the plugin was installed.

   The `key_names` configuration field in the above request defines the name of the field that the
   plugin looks for to read the key when authenticating requests. The plugin looks for the field in headers,
   query string parameters, and the request body.
  
1. **Send an unauthenticated request** 

   Try to access the service without providing the key:
   
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

1. **Send the wrong key**

   Try to access the service with the wrong key:
   
   ```sh
   curl -i http://localhost:8000/mock/anything \
     -H 'apikey:bad-key'
   ```
  
   You will receive an unauthorized response:
 
   ```text
   HTTP/1.1 401 Unauthorized
   ...
   {
     "message":"Invalid authentication credentials"
   }
   ```

1. **Send a valid request**

   Send a request with the valid key in the `apikey` header:

   ```sh
   curl -i http://localhost:8000/mock/anything \
     -H 'apikey:top-secret-key'
   ```

   You will receive a `200 OK` response.

<!--  
### Service based key authentication

The Key Authentication plugin can be enabled for specific services. The request is the same as above, but the `POST` request is sent 
to the service URL:

   ```sh
   curl -X POST http://localhost:8001/services/example_service/plugins \
     --data name=key-auth
   ```
### Route based key authentication

The Key Authentication plugin can be enabled for specific routes. The request is the same as above, but the `POST` request is sent to the route URL:

   ```sh
   curl -X POST http://localhost:8001/routes/example_route/plugins \
     --data name=key-auth
   ``` -->

### (Optional) Disable the plugin

If you are following this getting started guide section by section, you will need to use this API key 
in any requests going forward. If you don’t want to keep specifying the key, disable the plugin before moving on.


1. **Find the Key Authentication plugin ID**

   ```sh
   curl -X GET http://localhost:8001/plugins/
   ```
   
   You will receive a JSON response that contains the `id` field, similar to the following snippet:
   
   ```text
   ...
   "id": "2512e48d9-7by0-674c-84b7-00606792f96b"
   ...
   ```

1. **Disable the plugin**

   Use the plugin ID obtained above to `PATCH` the `enabled` field on the 
   installed Key Authentication plugin. Your request will look similar to this, 
   substituting the proper plugin ID:

   ```sh
   curl -X PATCH http://localhost:8001/plugins/2512e48d9-7by0-674c-84b7-00606792f96b \
     --data enabled=false
   ```

1. **Test disabled authentication**

   Now you can make a request without providing an API key:

   ```sh
   curl -i http://localhost:8000/mock/anything
   ```

   You should receive:

   ```text
   HTTP/1.1 200 OK
   ```

## 6. Load balancing

Load balancing is a method of distributing API request traffic across
multiple upstream services. Load balancing improves overall system responsiveness
and reduces failures by preventing overloading of individual resources. 

In the following example, you’ll use an application deployed across two different servers, or upstream targets. 
{{site.base_gateway}} needs to load balance across both servers, so that if one of the servers is unavailable, 
it automatically detects the problem and routes all traffic to the working server.

An [upstream](/gateway/latest/key-concepts/upstreams/) 
refers to the service applications sitting behind {{site.base_gateway}}, 
to which client requests are forwarded. In {{site.base_gateway}}, an upstream represents a virtual hostname and can be 
used to health check, circuit break, and load balance incoming requests over multiple [target](/gateway/api/admin-ee/latest/#/Targets/list-target-with-upstream/) backend services.

In this section, you’ll re-configure the service created earlier, (`example_service`) to point to an upstream 
instead of a specific host. For the purposes of our example, the upstream will point to two different targets, 
`httpbin.konghq.com` and `httpbun.com`. More commonly, targets will be instances of the same backend service running on different host systems.

Here is a diagram illustrating the setup:

<!--vale off-->

{% mermaid %}
flowchart LR
  A("`Route 
  (/mock)`")
  B("`Service
  (example_service)`")
  C(Load balancer)
  D(httpbin.konghq.com)
  E(httpbun.com)
  
  subgraph id1 ["`**KONG GATEWAY**`"]
    A --> B --> C
  end

  subgraph id2 ["`Targets (example_upstream)`"]
    C --> D & E
  end

  style id1 rx:10,ry:10
  style id2 stroke:none
{% endmermaid %}

<!--vale on-->

### Enable load balancing

In this section, you will create an upstream named `example_upstream` and add two targets to it.

1. **Create an upstream** 

   Use the Admin API to create an upstream named `example_upstream`:

   ```sh
   curl -X POST http://localhost:8001/upstreams \
     --data name=example_upstream
   ```

1. **Create upstream targets**

   Create two targets for `example_upstream`. Each request creates a new target, and 
   sets the backend service connection endpoint:
   
   ```sh
   curl -X POST http://localhost:8001/upstreams/example_upstream/targets \
     --data target='httpbun.com:80'
   curl -X POST http://localhost:8001/upstreams/example_upstream/targets \
     --data target='httpbin.konghq.com:80'
   ```

1. **Update the service**

   In the [services and routes](/gateway/latest/get-started/services-and-routes/) section of this guide, you created `example_service` which pointed
   to an explicit host, `http://httpbun.com`. Now you'll modify that service to point to the upstream instead:
   
   ```sh
   curl -X PATCH http://localhost:8001/services/example_service \
     --data host='example_upstream'
   ```

   You now have an upstream with two targets, `httpbin.konghq.com` and `httpbun.com`, and a service pointing to that upstream.

1. **Validate**


   Validate that the upstream you configured is working by visiting the route 
   `http://localhost:8000/mock` using a web browser or CLI.
  
   * **Web browser**: Visit `http://localhost:8000/mock` and refresh the page several times to see the site change from `httpbin` to `httpbun`.
   * **CLI**: Execute the command `curl -s http://localhost:8000/mock/headers |grep -i -A1 '"host"'` several times. You will see the hostname change between `httpbin` and `httpbun`.

<!-- ### What's next

You've completed the Get Started with Kong guide, but a lot more is possible with [{{site.base_gateway}}](/gateway/latest/). 
The following are guides to advanced features of {{site.base_gateway}}:

* [Monitoring with {{site.base_gateway}}](/gateway/{{ page.release }}/production/monitoring/)
* [Securing {{site.base_gateway}} with RBAC](/gateway/{{ page.release }}/kong-manager/auth/rbac/enable/) <span class="badge enterprise"></span>
* [Managing Workspaces and Team with {{site.base_gateway}}](/gateway/{{ page.release }}/kong-manager/auth/workspaces-and-teams/) <span class="badge enterprise"></span> -->

