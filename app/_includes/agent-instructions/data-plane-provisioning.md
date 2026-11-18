## Data plane provisioning

A data plane node carries the traffic. Provision it the same way the guide does, but take every value from the MCP tool responses instead of the page text.

### Region

The MCP server is reachable at a global endpoint, but the resources you create live in one {{site.konnect_short_name}} region. Read the region of the control plane from the tool response before you create anything, and keep every later call in that region.

### Keypair

Most guides create a data plane keypair locally with `openssl` and then register the public certificate. Keep the private key local. Send only the public certificate to {{site.konnect_short_name}}, or generate the keypair through the MCP tool if the tool offers it. Never put the private key in a request body.

### Pin the certificate

The data plane authenticates to the control plane with a pinned certificate. The certificate the node presents must be the one registered for the control plane. Use the certificate paths the tool response reports, not the placeholder paths on the page.

{% if agent_instructions_product == 'gateway' %}{% include agent-instructions/data-plane-setup/gateway.md %}
{% elsif agent_instructions_product == 'ai-gateway' %}{% include agent-instructions/data-plane-setup/ai-gateway.md %}
{% elsif agent_instructions_product == 'event-gateway' %}{% include agent-instructions/data-plane-setup/event-gateway.md %}
{% endif %}
