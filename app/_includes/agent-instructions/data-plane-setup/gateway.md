### {{site.base_gateway}} data plane

- Search the MCP for "data plane certificate" scoped to {{site.base_gateway}} and call its
  **create** tool with the JSON-escaped contents of `tls.crt`.
- Read the control plane's endpoints from `get_control_plane`: `config.control_plane_endpoint`
  and `config.telemetry_endpoint`. Strip the `https://` scheme and append `:443`.
- Start the data plane and pass the certificates inline. No volume mount is needed:

  `docker run --name <gateway-name>-dp -d -p 8000:8000 -p 8443:8443 -p 8001:8001 -p 8002:8002 -e KONG_ROLE=data_plane -e KONG_DATABASE=off -e KONG_KONNECT_MODE=on -e KONG_CLUSTER_MTLS=pki -e KONG_CLUSTER_CONTROL_PLANE=<cp-host>:443 -e KONG_CLUSTER_SERVER_NAME=<cp-host> -e KONG_CLUSTER_TELEMETRY_ENDPOINT=<tp-host>:443 -e KONG_CLUSTER_TELEMETRY_SERVER_NAME=<tp-host> -e KONG_LUA_SSL_TRUSTED_CERTIFICATE=system -e KONG_CLUSTER_CERT="$(cat tls.crt)" -e KONG_CLUSTER_CERT_KEY="$(cat key.crt)" kong/kong-gateway:latest`
- Search the MCP for "data plane node records" and confirm the new node appears.
