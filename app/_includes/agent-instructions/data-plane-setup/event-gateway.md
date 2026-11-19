### {{site.event_gateway}} data plane

- Search the MCP for "event gateway data plane certificate" and call its **create**
  tool, passing the JSON-escaped contents of `tls.crt`.
- Start the data plane, joining the same Docker network as the backing Kafka
  cluster so the backend bootstrap hostnames resolve:
  `docker run --name <gateway-name>-dp -d --network <kafka-network> -p <listener-ports> -e KONG_KONNECT_REGION=<region> -e KONG_KONNECT_DOMAIN=konghq.com -e KONG_KONNECT_GATEWAY_CLUSTER_ID=<gateway-id> -e KONG_KONNECT_CLIENT_CERT="$(cat tls.crt)" -e KONG_KONNECT_CLIENT_KEY="$(cat key.crt)" kong/kong-event-gateway:latest`

  `<listener-ports>` must match the ports this guide's listeners declare.
- Search the MCP for "event gateway nodes" and confirm the new node appears.

