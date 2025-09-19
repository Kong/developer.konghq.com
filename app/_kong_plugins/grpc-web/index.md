---
title: 'gRPC-Web'
name: 'gRPC-Web'

content_type: plugin

publisher: kong-inc
description: 'Allow browser clients to call gRPC services'


products:
    - gateway

works_on:
    - on-prem
    - konnect

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - serverless
icon: grpc-web.png

categories:
  - transformations

search_aliases:
  - grpc web

tags:
  - grpc

related_resources:
  - text: gRPC-Gateway plugin
    url: /plugins/grpc-gateway/
  - text: Use the gRPC-Web plugin to proxy HTTP requests to a gRPC service
    url: /how-to/use-grpc-web/

min_version:
  gateway: '2.1'
---

The gRPC-Web plugins allows access to a [gRPC](https://grpc.io/) service via the [gRPC-Web protocol](https://github.com/grpc/grpc/blob/master/doc/PROTOCOL-WEB.md#protocol-differences-vs-grpc-over-http2).
Primarily, this means JavaScript browser applications using the [gRPC-Web](https://github.com/grpc/grpc-web) library.

A service that presents a gRPC API can be used by clients written in many languages,
but the network specifications are oriented primarily to connections within a
data center. gRPC-Web lets you expose the gRPC API to the Internet so
that it can be consumed by browser-based JavaScript applications.

This plugin translates requests and responses between gRPC-Web and
[gRPC](https://github.com/grpc/grpc). The plugin supports both HTTP/1.1
and HTTP/2, over plaintext (HTTP) and TLS (HTTPS) connections.

## Why gRPC?

{% include /plugins/grpc.md %}