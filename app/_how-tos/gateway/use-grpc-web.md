---
title: Use the gRPC-Web plugin to proxy HTTP requests to a gRPC service
permalink: /how-to/use-grpc-web/
content_type: how_to

description: Set up the gRPC-Web plugin to proxy requests using a Protobuf definition.

products:
    - gateway

works_on:
    - on-prem
    - konnect

entities: 
  - plugin
  - service
  - route

plugins:
  - grpc-web

tags:
    - transformations

tldr:
    q: "How can I apply a Protobuf definition to a Service?"
    a: "Create a [Gateway Service](/gateway/entities/service/) with the `grpc` protocol, then create a [Route](/gateway/entities/route/) and enable the [gRPC-Web](/plugins/grpc-web/) plugin. Specify the path to your Protobuf file in the `config.proto` parameter."

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

min_version:
    gateway: '3.4'

automated_tests: false
---


## Create a Protobuf definition

Use the following command to create a sample Protobuf definition:

```sh
echo 'syntax = "proto2";

package hello;

service HelloService {
 rpc SayHello(HelloRequest) returns (HelloResponse);
 rpc LotsOfReplies(HelloRequest) returns (stream HelloResponse);
 rpc LotsOfGreetings(stream HelloRequest) returns (HelloResponse);
 rpc BidiHello(stream HelloRequest) returns (stream HelloResponse);
}

message HelloRequest {
 optional string greeting = 1;
}

message HelloResponse {
 required string reply = 1;
}
' > hello.proto
```

This sample definition uses `SayHello` method available on [grpcb.in](https://grpcb.in/).

## Add the Protobuf definition to your Docker container

Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:
{: data-deployment-topology="konnect" }
```sh
export KONNECT_DP_CONTAINER='your-dp-container-name'
```
{: data-deployment-topology="konnect" }

Use the following command to add `hello.proto` to the `/usr/local/kong` directory in your {{site.base_gateway}} Docker container:

```sh
docker cp hello.proto kong-quickstart-gateway:/usr/local/kong
```
{: data-deployment-topology="on-prem" }

```sh
docker cp hello.proto $KONNECT_DP_CONTAINER:/usr/local/kong
```
{: data-deployment-topology="konnect" }

## Create a Gateway Service and a Route

{% include /how-tos/steps/grpc-entities.md %}

## Enable the gRPC-Web plugin

Configure the plugin to use the Protobuf definition we created:

{% entity_examples %}
entities:
    plugins:
    - name: grpc-web
      route: http-route
      config:
        proto: usr/local/kong/hello.proto
{% endentity_examples %}

## Validate

To validate that the configuration is working as expected, send a `POST` request to one of the RPC methods used in the Protobuf definition.

For example:
{% validation request-check %}
method: POST
url: '/hello.HelloService/SayHello'
status_code: 200
body:
  greeting: MyName
headers:
  - 'x-grpc: true'
  - 'Content-Type: application/json'
{% endvalidation %}