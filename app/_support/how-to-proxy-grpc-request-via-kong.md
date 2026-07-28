---
title: How to proxy a gRPC request via Kong
content_type: support
description: Add `http2` to `proxy_listen` / `KONG_PROXY_LISTEN`, then create a Service and Route with the `grpc` protocol to proxy client requests to a gRPC upstream.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: grpcb.in
    url: https://grpcb.in/
  - text: Manage gRPC services with Kong
    url: https://konghq.com/blog/manage-grpc-services-kong
tldr:
  q: How do I proxy a gRPC request through Kong?
  a: |
    Kong has native support for gRPC. Add `http2` to the relevant `proxy_listen` / `KONG_PROXY_LISTEN` entry, then create a Service with `protocol=grpc` and a Route with `protocols=grpc`. Requests sent with a gRPC client (such as `grpcurl`) to the Route are proxied to the gRPC upstream.
---

## Overview

How to proxy a gRPC request via Kong?

## Steps

Kong provides native support for gRPC.

Assuming Kong is running at `http://localhost:8001` and the Kong Admin API is exposed at `http://localhost:8001`.

We will show a demo to proxy a gRPC request to `grpc://grpcb.in:9000`.

For the case RBAC is disabled, remove the `kong-admin-token` header from the curl commands below.

0. Confirm `proxy_listen` or `KONG_PROXY_LISTEN`:

   ```conf
   # Make sure http2 has been added to 1 of the below parameters
   # e.g
   proxy_listen = 0.0.0.0:8000 http2, 0.0.0.0:8443 http2 ssl
   KONG_PROXY_LISTEN = 0.0.0.0:8000 http2, 0.0.0.0:8443 http2 ssl

   # Please remember to restart Kong after you modified any of them
   ```

1. Create service object:

   ```bash
   curl -XPOST localhost:8001/services \
   -H 'kong-admin-token:<please-replace-with-your-kong-token>' \
   --data name=grpcbin \
   --data protocol=grpc \
   --data host=grpcb.in \
   --data port=9000
   ```

2. Create route object:

   ```bash
   curl -X POST localhost:8001/services/grpcbin/routes \
   -H 'kong-admin-token:<please-replace-with-your-kong-token>' \
   --data protocols=grpc \
   --data name=grpcbin-all \
   --data paths=/
   ```

3. Send gRPC request via Kong:

   ```bash
   grpcurl -v -d '{"greeting": "Kong!"}' \
   -H 'kong-debug: 1' -plaintext \
   localhost:8000 hello.HelloService.SayHello
   ```

   And we will get the response below:

   ```
   Resolved method descriptor:
   rpc SayHello ( .hello.HelloRequest ) returns ( .hello.HelloResponse );

   Request metadata to send:
   kong-debug: 1

   Response headers received:
   content-type: application/grpc
   date: Thu, 01 Sep 2026 02:32:12 GMT
   kong-route-id: 8e1fe0ad-e81a-499f-a031-e77029838342
   kong-route-name: grpcbin-all
   kong-service-id: 275a7cc5-ed7e-4510-a630-76c90ec843b9
   kong-service-name: grpcbin
   server: openresty
   via: kong/3.14.0.0-enterprise-edition
   x-kong-proxy-latency: 1
   x-kong-upstream-latency: 568

   Response contents:
   {
     "reply": "hello Kong!"
   }

   Response trailers received:
   (empty)
   Sent 1 request and received 1 response
   ```
