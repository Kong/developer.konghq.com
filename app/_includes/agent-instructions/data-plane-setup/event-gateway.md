### Event Gateway data plane

Create or reuse an {{site.event_gateway}} and register a data plane certificate for it. Read the event gateway ID and the certificate ID from the tool response.

Start the node with the `kong/kong-event-gateway` image. Set `KONG_KONNECT_GATEWAY_CLUSTER_ID` to the event gateway ID, and pass the region, domain, and client certificate values the tool response reports.

### Confirm the node connected

List the event gateway nodes for the gateway and confirm the new node appears with a connected status. Only then continue with the guide.
