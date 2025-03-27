---
title: 'gRPC-gateway'
name: 'gRPC-gateway'

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
    - cloud-gateways
    - serverless
icon: grpc-gateway.png

categories:
  - transformations

search_aliases:
  - grpc gateway
---

The gRPC-Gateway plugin allows you to send JSON requests to a gRPC service. A
specially configured `.proto` file handles the conversion of the JSON request
into one that the gRPC service can handle. This allows you to expose RESTful-style
interfaces that talk to a gRPC service.

This plugin's implementation is similar to [gRPC-gateway](https://grpc-ecosystem.github.io/grpc-gateway/).

![grpc-gateway](https://grpc-ecosystem.github.io/grpc-gateway/assets/images/architecture_introduction_diagram.svg)

Image credit: [grpc-gateway](https://grpc-ecosystem.github.io/grpc-gateway/)

## Why gRPC?

{% include /plugins/grpc.md %}
