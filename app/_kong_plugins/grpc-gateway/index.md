---
title: 'gRPC-Gateway'
name: 'gRPC-Gateway'

content_type: plugin

publisher: kong-inc
description: 'Access gRPC services through HTTP REST'


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
icon: grpc-gateway.png

categories:
  - transformations

tags:
  - transformations
  - grpc

search_aliases:
  - grpc gateway

related_resources:
  - text: gRPC-Web plugin
    url: /plugins/grpc-web/
  - text: Use the gRPC-Gateway plugin to proxy HTTP requests to a gRPC service
    url: /how-to/use-grpc-gateway/

min_version:
  gateway: '2.1'
---

The gRPC-Gateway plugin allows you to send JSON requests to a [gRPC](https://grpc.io/) service. A
specially configured `.proto` file handles the conversion of the JSON request
into one that the gRPC service can handle. This allows you to expose RESTful-style
interfaces that communicate with a gRPC service.

This plugin's implementation is similar to [gRPC-gateway](https://grpc-ecosystem.github.io/grpc-gateway/).

## Why gRPC?

{% include /plugins/grpc.md %}
