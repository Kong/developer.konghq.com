---
title: Use the gRPC-Web plugin to proxy HTTP requests to a gRPC service
content_type: how_to

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
    q: ""
    a: ""

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
---


## 1. Create a Protobuf definition

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

## 2. Add the Protobuf definition to your Docker container

Use the following command to add `hello.proto` to the `/usr/local/kong` directory in your {{site.base_gateway}} Docker container:

```sh
docker cp hello.proto kong-quickstart-gateway:/usr/local/kong
```

## 3. Create a Gateway Service and a Route

{% include /how-tos/steps/grpc-entities.md %}

## 4. Enable the gRPC-Web plugin

Configure the plugin to use the Protobuf definition we created:

{% entity_examples %}
entities:
    plugins:
    - name: grpc-web
      route: http-route
      config:
        proto: usr/local/kong/hello.proto
{% endentity_examples %}

## 5. Validate

To validate that the configuration is working as expected, send a POST request to one of the RPC methods used in the Protobuf definition.

For example:
{% validation request-check %}
method: POST
url: '/hello.HelloService/SayHello'
status_code: 200
body:
  greeting: MyName
{% endvalidation %}

