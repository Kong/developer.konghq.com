### {{site.ai_gateway}} data plane

Create or reuse an {{site.ai_gateway}} and register a data plane certificate for it. Read the {{site.ai_gateway}} ID and the certificate ID from the tool response.

Start the node with the `kong/kong-ai-gateway` image. Set `KONG_ROLE=data_plane`, `KONG_DATABASE=off`, and `KONG_KONNECT_MODE=on`, and pass the control plane endpoint, the telemetry endpoint, and the certificate paths the tool response reports.

### Confirm the node connected

List the {{site.ai_gateway}} nodes for the gateway and confirm the new node appears with a connected status. Only then continue with the guide.
