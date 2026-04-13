---
# REQUIRED: The title that appears at the top of the page
title: About retries attribute of service object

# REQUIRED: Must be set to "support" for support articles
content_type: support

# OPTIONAL: A brief description of what this support article covers
# This appears in search results and meta tags
description: About retries attribute of service object.

# OPTIONAL: Which Kong products this article applies to
# Common values: gateway, konnect, mesh, insomnia, deck
products:
  - gateway

# REQUIRED for Gateway support articles (when products includes "gateway"); OPTIONAL otherwise
# accepted values: on-prem, konnect
works_on:
  - on-prem
  - konnect


# OPTIONAL: Related resources that provide additional context
# Each entry should have a text label and a url
related_resources:
  - text: Link text for related documentation
    url: /path/to/related/page/
  - text: Another related resource
    url: /path/to/another/page/

# OPTIONAL: TL;DR section that appears at the top of the article
# Provides a quick question and answer summary
tldr:
  q: retries attribute of service object
  a: |
    The articles describe the end-to-end steps of working with service object

---

Below is an example of installing Kong on Docker.

Please install Kong on Docker by following the official guide: Kong Docker Installation .

## 1. How to check the behavior of the retries attribute?

**Step 1**: Set KONG_LOG_LEVEL=debug and reload Kong.

In your container, set KONG_LOG_LEVEL to **debug**

```bash
$ echo "KONG_LOG_LEVEL=debug kong reload exit" | docker exec -i kong-ee /bin/sh
```

**Step 2**: Run the httpbin container.

```bash
$ docker run -d --name httpbin --network=kong-ee-net -p 80:80 kennethreitz/httpbin
```

**Step 3**: Create a service object linked to the httpbin container, setting retries

```bash
$ curl -i -X POST http://localhost:8001/services \
  --data name=example_service \
  --data url='http://httpbin/anything' \
  --data retries=5
```

**Step 4**: Create a route object for the above service:

```bash
$ curl -i -X POST http://localhost:8001/services/example_service/routes \
  --data 'paths[]=/mock' \
  --data name=mocking
```

**Step 5**: Access the route successfully, receiving a 200 response:

```bash
$ curl localhost:8000/mock -i

HTTP/1.1 200 OK
Content-Type: application/json
Content-Length: 406
Connection: keep-alive
Server: gunicorn/19.9.0
Date: Thu, 08 Apr 2021 06:44:09 GMT
Access-Control-Allow-Origin: *
Access-Control-Allow-Credentials: true
X-Kong-Upstream-Latency: 13
X-Kong-Proxy-Latency: 4
Via: kong/2.3.3.0-enterprise-edition
...
```

**Step 6**: Stop the httpbin container, then access the route again:

```bash
$ docker stop httpbin
$ curl localhost:8000/mock -i

HTTP/1.1 502 Bad Gateway
Server: openresty
Date: Thu, 08 Apr 2021 06:48:30 GMT
Content-Type: application/json; charset=utf-8
Connection: keep-alive
Content-Length: 75
X-Kong-Upstream-Latency: 3071
X-Kong-Proxy-Latency: 30607
Via: kong/2.3.3.0-enterprise-edition

{
  "message":"An invalid response was received from the upstream server"
}
```

You can check the Kong logs to observe retry attempts, as shown below:

```bash
$ docker logs -f kong-ent

DATE [debug] ... balancer(): setting address (try 1): xxx.xxx.xxx.xxx:xxx
...
...
DATE [error] ... connect() failed (110: Operation timed out) while connecting to upstream, client: xxx.xxx.xxx.xxx, server: kong, request: "GET /xxx HTTP/1.1", upstream: "xxx", host: "xxx"
DATE [debug] ... balancer(): setting address (try 2): xxx.xxx.xxx.xxx:xxx
...
...
```

## 2. Does the service object only retry when an upstream object is set?

No, the service object can retry requests even if an upstream object has not been set.

## 3. Does the service object retry on HTTP 4xx/5xx responses?

No, retries happen only for TCP connection errors. However, Kong can perform HTTP and TCP health checks using the upstream object. For more details, see the Health Checks and Circuit Breakers documentation .


