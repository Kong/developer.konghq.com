## Data plane provisioning

The MCP provisions the control plane side only. Starting a data plane is a
local Docker action the MCP cannot perform. **Do not run the quickstart script
to do this**: it creates another control plane rather than attaching a data
plane to the existing one.

- **Determine the region** from the Konnect API/MCP host being used (a `us.` host means `us`). **Not** `inferred_region` from `get_users_me`, which reflects the user's geography, not the gateway's.
- **Generate a key pair** locally:
  `openssl req -new -x509 -nodes -newkey rsa:2048 -days 3650 -subj "/CN=<gateway-name>-dp/C=US" -keyout key.crt -out tls.crt`
- **Pin the certificate and start the data plane** using the product-specific steps that follow. Do not substitute commands from another product's guide.

{% if agent_instructions_product == 'gateway' %}{% include agent-instructions/data-plane-setup/gateway.md %}
{% elsif agent_instructions_product == 'ai-gateway' %}{% include agent-instructions/data-plane-setup/ai-gateway.md %}
{% elsif agent_instructions_product == 'event-gateway' %}{% include agent-instructions/data-plane-setup/event-gateway.md %}
{% endif %}
