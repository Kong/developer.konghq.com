#### {{site.ai_gateway}} data plane

- Search the MCP for "ai gateway data plane certificate" and call its **create**
  tool with the JSON-escaped contents of `tls.crt`.
- Read the {{site.ai_gateway}} endpoints from `get_ai_gateway`: `endpoints.configuration`
  and `endpoints.telemetry`. Strip the `https://` scheme and append `:443`.
- Start the data plane using the same `KONG_CLUSTER_*` scheme with the {{site.ai_gateway}} image:

  `docker run --name <gateway-name>-dp -d -p 8000:8000 -p 8443:8443 -e KONG_ROLE=data_plane -e KONG_DATABASE=off -e KONG_KONNECT_MODE=on -e KONG_CLUSTER_MTLS=pki -e KONG_CLUSTER_CONTROL_PLANE=<cp-host>:443 -e KONG_CLUSTER_SERVER_NAME=<cp-host> -e KONG_CLUSTER_TELEMETRY_ENDPOINT=<tp-host>:443 -e KONG_CLUSTER_TELEMETRY_SERVER_NAME=<tp-host> -e KONG_LUA_SSL_TRUSTED_CERTIFICATE=system -e KONG_CLUSTER_CERT="$(cat tls.crt)" -e KONG_CLUSTER_CERT_KEY="$(cat key.crt)" kong/kong-ai-gateway:latest`

- Search the MCP for "ai gateway nodes" and confirm the new node appears.
