---
title: gRPC requests in Insomnia

description: Insomnia allows you to configure and send different types of requests.

content_type: reference
layout: reference

products:
- insomnia

breadcrumbs:
- /insomnia/

tags:
- collections

related_resources:
  - text: Collections
    url: /insomnia/collections/
  - text: Requests
    url: /insomnia/requests/

faqs:
  - q: Are there any limitations when using gRPC in Insomnia?
    a: |
      Yes, currently Insomnia does not support the following features with gRPC:
      * Unit testing
      * Request chaining
      * gRPC deadlines
      * Persistence of request/responses and history
---

With the growing emergence of Internet of Things (IoT), microservices and mesh networks, APIs need to be more performant and scalable than ever before. This has given rise to the growing adoption of [gRPC](https://grpc.io/), a high-performance, open source, universal RPC framework developed at Google.

Insomnia supports making gRPC requests. You can create one by clicking the **+** button on the left panel of a collection and selecting **gRPC Request**. Once this is done, configure your request:

1. Add the host and port.
1. Click the file icon to upload a [Protobuf file](#proto-file-management). You can find sample Protobuf files at [grpcb.in](https://grpcb.in/).
1. Select a method.
1. Enter a request body based on the [request type](#grpc-request-types).

## Protobuf file management

Insomnia allows you to upload Protobuf files to a request. You can upload a single file or a directory containing multiple files.

### Buf Schema Registry reflection

Insomnia supports the [Buf Schema Registry](https://buf.build/docs/bsr/introduction) for reflection.

The BSR doesn't require your gRPC servers to expose any reflection endpoints, it's all managed for you externally. You'll need to configure an [API Token](https://buf.build/docs/bsr/authentication) and your [BSR module path](https://buf.build/docs/bsr/module/dependency-management/) to get started.

To configure this for your request:

1. Create a new gRPC request and enter the service host, `grpcs://grpcb.in:9001` for example. 
1. Right-click the request in the left panel and click **Settings**. 
1. Select the **Use the Buf Schema Registry API** checkbox and enter your configuration.
1. Click the sync icon to fetch your schema information from the BSR. 
1. Click **Select Method** and select an RPC from the dropdown list.

For more information, see the Buf [Reflection API](https://buf.build/docs/bsr/reflection/overview) docs.

### gRPC Server reflection

Insomnia supports [gRPC Server Reflection](https://github.com/grpc/grpc/blob/master/doc/server-reflection.md).

If the server you are sending requests to supports gRPC Server Reflection, you can use this as an alternative to adding local Protobuf files to Insomnia. 

To use gRPC Server Reflection:

1. Create a new gRPC request and enter the service host, `grpcs://grpcb.in:9001` for example.
1. Click the sync icon to fetch your schema information from the server. 
1. Click **Select Method** and select an RPC from the dropdown list.

## gRPC request types

Insomnia supports all four RPC types defined by gRPC:
* [Unary](https://grpc.io/docs/what-is-grpc/core-concepts/#unary-rpc)
* [Client Streaming](https://grpc.io/docs/what-is-grpc/core-concepts/#client-streaming-rpc)
* [Server Streaming](https://grpc.io/docs/what-is-grpc/core-concepts/#server-streaming-rpc)
* [Bidirectional Streaming](https://grpc.io/docs/what-is-grpc/core-concepts/#bidirectional-streaming-rpc). 

The following examples use [hello.proto](https://github.com/moul/pb/blob/master/hello/hello.proto) from grpcb.in. 
These examples expect a request body containing a `greeting` element. For example:

```json
{
    "greeting": "jane"
}
```

### Unary

`/hello.HelloService/SayHello` is unary RPC. You send a single message, and the server responds with a single message.

Specify a body, and click **Send**.

### Server streaming

`/hello.HelloService/LotsOfReplies` is server streaming RPC. You send a single message, and the server responds with multiple messages.

Specify a body, and click **Send**.

{:.warning}
> **Note**: The time it takes to respond depends on the server. In the example below, the second request uses grpcbin.proto, where the server stream responds much slower, and is easier to visualize.

### Client streaming

`/hello.HelloService/LotsOfGreetings` is client streaming RPC. You send multiple messages and the server responds with a single message.

Click **Start** to open a channel with the server, then edit the body with the contents of your first message and click **Stream** to send that message. You should see a read-only snapshot of the message appear as a tab. You can now edit the contents in the **Body** tab again, and click **Stream** each time you want to send a new message. Once all messages have been sent, click **Commit** and the server should respond accordingly.

### Bidirectional streaming

`/hello.HelloService/BiDiHello` is bidirectional streaming RPC. You send multiple messages, and the server responds with multiple messages.

This is a combination of server and client streaming. As such, the steps to send messages are identical to client streaming above, and the manner in which the server responds is identical to server streaming. Be sure to click **Commit** once you have finished sending all your messages, and allow the server to terminate the connection.

## TLS/SSL

gRPC endpoints can be secured by TLS, and Insomnia allows you to connect to these endpoints using simple SSL. In order to enable TLS, prefix the host with `grpcs://`.

For example, grpcb.in has an unsecured endpoint at `grpcb.in:9000`, and a secured endpoint at `grpcb.in:9001`. Making a request to `grpcb.in:9001` will fail, while making a request to `grpcs://grpcb.in:9001` will succeed.