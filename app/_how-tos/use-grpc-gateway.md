---
title: Use the gRPC-Gateway plugin to proxy HTTP requests to a gRPC service
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
  - grpc-gateway

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

## 2. Add the Protobuf definition to your Docker container

Use the following command to add `hello-gateway.proto` to the `/usr/local/kong` directory in your {{site.base_gateway}} Docker container:

```sh
docker cp hello-gateway.proto kong-quickstart-gateway:/usr/local/kong
```

## 3. Create a Gateway Service and a Route

{% include /how-tos/steps/grpc-entities.md %}

## 4. Enable the gRPC-Gateway plugin

Configure the plugin to use the Protobuf definition we created:

{% entity_examples %}
entities:
    plugins:
    - name: grpc-gateway
      route: http-route
      config:
        proto: usr/local/kong/hello-gateway.proto
{% endentity_examples %}

## 5. Validate

To validate that the configuration is working as expected, you can:
* Send an GET request to `/v1/messages/` or `/v1/messages/legacy/`, with a name in the URL
* Send a POST request to `/v1/messages/` with a name in the request body

For example:
{% validation request-check %}
url: '/v1/messages/MyName'
status_code: 200
{% endvalidation %}

{% validation request-check %}
method: POST
url: '/v1/messages/'
body:
  name: MyName
status_code: 200
{% endvalidation %}

