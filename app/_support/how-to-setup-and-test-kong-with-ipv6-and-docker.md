---
title: How to set up and test Kong with IPv6 and Docker
content_type: support
description: Create an IPv6-enabled Docker network and configure Kong's `proxy_listen` to serve IPv6 traffic.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: Docker IPv6 daemon configuration
    url: https://docs.docker.com/config/daemon/ipv6/
tldr:
  q: How do I set up and test Kong with IPv6 in Docker?
  a: |
    Create an IPv6-enabled Docker network, then set `KONG_PROXY_LISTEN` (or `proxy_listen`) to include both an IPv6 listener (e.g. `[::0]:8000`) and the existing IPv4 listener. After attaching Kong and an upstream container to the network, create Services and Routes using the upstream's IPv6 address, and confirm traffic with `curl -6`.
---

## Overview

This article describes how to set up Kong to proxy IPv6 traffic with a Docker installation.

Note: Docker can only route IPv6 packets when installed on Linux, not macOS or Windows. See Docker's IPv6 daemon configuration docs.

## Steps

1. Create an IPv6 network to attach the containers.

   Use the following command to make a standalone Docker network that supports IPv6:

   ```bash
   docker network create --ipv6 --attachable --gateway 2001:3984:3989::1 --subnet 2001:3984:3989::/64 kong_net_ipv6
   ```

2. Configure Kong to have an IPv6 listener in your docker compose file.

   Set the following environment variable in your Docker command / compose file to enable IPv6 listening:

   ```bash
   KONG_PROXY_LISTEN=[::0]:8000, [::0]:8443 ssl, 0.0.0.0:8000, 0.0.0.0:8443 ssl
   ```

3. Use the following compose file, or modify your own, to include the external network and an echo server for testing:

   ```yaml
   version: "3"

   networks:
     kong_net_ipv6:
       external: true

   services:
    echo-1:
     image: 'ealen/echo-server:latest'
     container_name: echo-1
     ports:
      - 80:80
     networks:
       kong_net_ipv6:

    kong-enterprise:
     image: 'kong:kong-gateway...'
     networks:
       kong_net_ipv6:
     environment:
      - KONG_PROXY_LISTEN=[::0]:8000, [::0]:8443 ssl, 0.0.0.0:8000, 0.0.0.0:8443 ssl
     .
     .
   ```

   Run `docker compose up` to attach the echo server and Kong to the IPv6 network.

4. Find the echo container's IPv6 address.

   Inspect the Docker network to get the IPv6 address of the echo server:

   ```bash
   docker network inspect kong_net_ipv6
   ```

   This will return a list of containers connected to the network. Find the one labeled `echo-1` like the excerpt below:

   ```json
               "d2d4e6251e7fba5272f28f76b34dbff67a534b15c382f28ab433ead584b21759": {
                   "Name": "echo-1",
                   "EndpointID": "582358e6ca9ee73f4a1fefa40db36f0c1764825913a9e9920dfd2eaa2c53be93",
                   "MacAddress": "02:42:ac:14:00:0a",
                   "IPv4Address": "172.20.0.10/16",
                   "IPv6Address": "2001:3984:3989::a/64"
               }
   ```

   Copy the `IPv6Address` value for use in the next step.

5. Program Kong routes and services using the IPv6 address of the echo container.

   Use the following curl commands to insert a route and service to Kong using that IPv6 address:

   ```bash
   curl -X POST http://127.0.0.1:8001/services -H 'Content-Type: application/json' -H 'kong-admin-token:admin' -d '{"name":"ipv6-test-svc", "protocol":"http", "host": "[2001:3984:3989::a]", "port": 80}'
   ```

   ```bash
   curl -X POST http://127.0.0.1:8001/services/ipv6-test-svc/routes -H 'Content-Type: application/json' -H 'kong-admin-token:admin' -d '{"name":"ipv6-test-route","paths":["/ipv6_echo_test"],"protocols":["http","https"]}'
   ```

6. Test that the communication works with curl:

   ```bash
   curl -g -6 'http://[::1]:8000/ipv6_echo_test' -v -H "kong-debug:1" | jq .
   *   Trying ::1...
   * TCP_NODELAY set
     % Total    % Received % Xferd  Average Speed   Time    Time     Time  Current
                                    Dload  Upload   Total   Spent    Left  Speed
     0     0    0     0    0     0      0      0 --:--:-- --:--:-- --:--:--     0* Connected to ::1 (::1) port 8000 (#0)
   > GET /ipv6_echo_test HTTP/1.1
   > Host: [::1]:8000
   > User-Agent: curl/7.58.0
   > Accept: */*
   > kong-debug:1
   >
   < HTTP/1.1 200 OK
   < Content-Type: application/json; charset=utf-8
   < Content-Length: 744
   < Connection: keep-alive
   < Kong-Route-Id: b59a9c03-abf0-41ae-b72f-8448da97d7ca
   < Kong-Route-Name: ipv6-test-route
   < Kong-Service-Id: 43206f9f-1dbc-4190-bc9c-c740acc56043
   < Kong-Service-Name: ipv6-test-svc
   < ETag: W/"2e8-vxrfXbTTuJ5SZmce9nmFHAPGgdc"
   < Date: Tue, 09 Aug 2026 07:28:31 GMT
   <
   { [744 bytes data]
   100   744  100   744    0     0  41333      0 --:--:-- --:--:-- --:--:-- 46500
   * Connection #0 to host ::1 left intact
   {
     "host": {
       "hostname": "[2001:3984:3989::a]",
       "ip": "2001:3984:3989::b",
       "ips": []
     },
     "http": {
       "method": "GET",
       "baseUrl": "",
       "originalUrl": "/",
       "protocol": "http"
     },
     "request": {
       "params": {
         "0": "/"
       },
       "query": {},
       "cookies": {},
       "body": {},
       "headers": {
         "host": "[2001:3984:3989::a]",
         "connection": "keep-alive",
         "x-forwarded-for": "2001:3984:3989::1",
         "x-forwarded-proto": "http",
         "x-forwarded-host": "[::1]",
         "x-forwarded-port": "8000",
         "x-forwarded-path": "/ipv6_echo_test",
         "x-forwarded-prefix": "/ipv6_echo_test",
         "x-real-ip": "2001:3984:3989::1",
         "user-agent": "curl/7.58.0",
         "accept": "*/*",
         "kong-debug": "1"
       }
     },
     "environment": {
       "PATH": "/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin",
       "HOSTNAME": "d2d4e6251e7f",
       "NODE_VERSION": "16.16.0",
       "YARN_VERSION": "1.22.19",
       "HOME": "/root"
     }
   }
   ```

   IPv6 traffic has been successfully routed.

   NOTE: If you require Kong to properly respond to IPv6 DNS queries, you'll need to enable the AAAA record in the environment variables of your Kong container using the following parameter:

   ```bash
   KONG_DNS_ORDER=AAAA,LAST,SRV,A,CNAME
   ```

   As of writing this article, this DNS feature is labeled experimental and therefore unsupported.
