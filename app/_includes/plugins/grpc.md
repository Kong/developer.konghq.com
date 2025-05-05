Unlike JSON, [gRPC](https://grpc.io/about/)
is a binary protocol, which uses [Protobuf](https://protobuf.dev/)
definitions to describe how the data is marshalled and unmarshalled. Because
binary data is used instead of text, it's a more efficient way to transmit data
over a network. However, this also makes gRPC harder to work with, because inspecting
what went wrong is more challenging. Additionally, few clients natively handle gRPC.

For flexibility and compatibility with RESTful expectations, the gRPC-Gateway
plugin offers more configurability, whereas the gRPC-Web plugin adheres more
directly to the Protobuf specification.