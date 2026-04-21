---
title: About the retries attribute of the service object
content_type: support
description: How Kong's retry behavior works for service objects, including how to observe retries in debug logs.
products:
  - gateway
works_on:
  - on-prem
  - konnect
tldr:
  q: How do I check the behavior of the retries attribute?
  a: |
    When an upstream is unreachable, Kong retries the connection up to the configured number of times. You can observe this in debug logs.
faqs:
  - q: Does the service object only retry when an upstream object is set?
    a: No, the service object can retry requests even if an upstream object has not been set.
  - q: Does the service object retry on HTTP 4xx/5xx responses?
    a: No, retries happen only for TCP connection errors. However, {{site.base_gateway}} can perform HTTP and TCP health checks using the upstream object. For more details, see the Health Checks and Circuit Breakers documentation.
---

## How to check the behavior of the retries attribute

1. Set `KONG_LOG_LEVEL=debug` and reload {{site.base_gateway}}.

   In your container, set `KONG_LOG_LEVEL` to `debug`

   ```bash
   echo "KONG_LOG_LEVEL=debug kong reload exit" | docker exec -i kong-ee /bin/sh
   ```

2. Run the httpbin container.

   ```bash
   docker run -d --name httpbin --network=kong-ee-net -p 80:80 kong/httpbin
   ```

3. Create a service object linked to the httpbin container, setting retries.

   ```bash
   curl -i -X POST http://localhost:8001/services \
     --data name=example_service \
     --data url='http://httpbin/anything' \
     --data retries=5
   ```

4. Create a route object for the above service:

   ```bash
   curl -i -X POST http://localhost:8001/services/example_service/routes \
     --data 'paths[]=/mock' \
     --data name=mocking
   ```

5. Access the route successfully, receiving a 200 response:

   ```bash
   curl localhost:8000/mock -i

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

6. Stop the httpbin container, then access the route again:

   ```bash
   docker stop httpbin
   curl localhost:8000/mock -i

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

   You can check the {{site.base_gateway}} logs to observe retry attempts, as shown below:

   ```bash
   docker logs -f kong-ent

   DATE [debug] ... balancer(): setting address (try 1): xxx.xxx.xxx.xxx:xxx
   ...
   ...
   DATE [error] ... connect() failed (110: Operation timed out) while connecting to upstream, client: xxx.xxx.xxx.xxx, server: kong, request: "GET /xxx HTTP/1.1", upstream: "xxx", host: "xxx"
   DATE [debug] ... balancer(): setting address (try 2): xxx.xxx.xxx.xxx:xxx
   ...
   ...
   ```
