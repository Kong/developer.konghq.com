### Gateway data plane

Create or reuse a {{site.base_gateway}} control plane, then register a data plane certificate for it. Read the control plane ID and the certificate ID from the tool response.

Start the node with the `kong/kong-gateway` image. Set `KONG_ROLE=data_plane`, `KONG_DATABASE=off`, and `KONG_KONNECT_MODE=on`, and pass the control plane endpoint, the telemetry endpoint, and the certificate paths the tool response reports.

### Confirm the node connected

List the gateway nodes for the control plane and confirm the new node appears with a connected status. Only then continue with the guide.
