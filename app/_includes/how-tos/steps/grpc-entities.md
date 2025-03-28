In this example, we want a [Route](/gateway/entities/route/) that serves the HTTP protocol but proxies to a [Gateway Service](/gateway/entities/service/) with the gRPC protocol.
For testing purposes, we'll use [grpcb.in](https://grpcb.in/) as the upstream service.
{% entity_examples %}
entities:
  services:
    - name: example-grpc-service
      protocol: grpc
      host: grpcb.in
      port: 9000
  routes:
    - name: http-route
      protocols:
      - http
      paths:
      - /
      service: 
        name: example-grpc-service
{% endentity_examples %}