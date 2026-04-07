---
title: Use the gRPC-Gateway plugin to proxy HTTP requests to a gRPC service
permalink: /how-to/use-grpc-gateway/
content_type: how_to

description: Set up the gRPC-Gateway plugin to proxy requests using a Protobuf definition.
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
  - grpc-gateway

tags:
    - transformations

tldr:
    q: "How can I apply a Protobuf definition to a Service?"
    a: "Create a [Gateway Service](/gateway/entities/service/) with the `grpc` protocol, then create a [Route](/gateway/entities/route/) and enable the [gRPC-Gateway](/plugins/grpc-gateway/) plugin. Specify the path to your Protobuf file in the `config.proto` parameter."

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
echo 'syntax = "proto3";

package hello;

service HelloService {
 rpc SayHello(HelloRequest) returns (HelloResponse) {
   option (google.api.http) = {
     get: "/v1/messages/{name}"
     additional_bindings {
       get: "/v1/messages/legacy/{name=**}"
     }
     post: "/v1/messages/"
     body: "*"
   };
 }
}


// The request message containing the name.
message HelloRequest {
 string name = 1;
}

// The response message containing the greeting
message HelloResponse {
 string message = 1;
}' > hello-gateway.proto
```

This sample definition modifies the `SayHello` method available on [grpcb.in](https://grpcb.in/) and will return a message containing "Hello" followed by a name that can be specified either in the URL for `GET` requests or in the request body for `POST` requests.

## Add the Protobuf definition to your Docker container

{% konnect %}
content: |
  Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:

  ```sh
  export KONNECT_DP_CONTAINER='your-dp-container-name'
  ```
{% endkonnect %}

Use the following command to add `hello-gateway.proto` to the `/usr/local/kong` directory in your {{site.base_gateway}} Docker container:

{% on_prem %}
content: |
  ```sh
  docker cp hello-gateway.proto kong-quickstart-gateway:/usr/local/kong
  ```
{% endon_prem %}

{% konnect %}
content: |
  ```sh
  docker cp hello-gateway.proto $KONNECT_DP_CONTAINER:/usr/local/kong
  ```
{% endkonnect %}

## Create a Gateway Service and a Route

{% include /how-tos/steps/grpc-entities.md %}

## Enable the gRPC-Gateway plugin

Configure the plugin to use the Protobuf definition we created:

{% entity_examples %}
entities:
    plugins:
    - name: grpc-gateway
      route: http-route
      config:
        proto: /usr/local/kong/hello-gateway.proto
{% endentity_examples %}

## Validate

To validate that the configuration is working as expected, you can:
* Send a `GET` request to `/v1/messages/` or `/v1/messages/legacy/`, with a name in the URL:
  {% validation request-check %}
  url: '/v1/messages/MyName'
  status_code: 200
  {% endvalidation %}
* Send a `POST` request to `/v1/messages/` with a name in the request body:
  {% validation request-check %}
  method: POST
  url: '/v1/messages/'
  body:
    name: MyName
  status_code: 200
  {% endvalidation %}

