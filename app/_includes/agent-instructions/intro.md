## Konnect Deployments: Instructions for Agents - {{site.konnect_product_name}} MCP

Use this section only when the {{site.konnect_product_name}} MCP server is available and connected.
If a prerequisite tells you to run the quickstart script, ignore that instruction.
If the {{site.konnect_product_name}} MCP server is not connected, ignore this section and
follow the steps in the guide instead, and run the quickstart script as the prerequisites tell you.

- If the {{site.konnect_product_name}} MCP server is available and connected, you MUST use its tools for Konnect.
- Do not use `curl` for Konnect.
- Do not run the quickstart script.
- Discover the tools yourself.
- Call tools through code mode.
- Read before you write. List or get every entity that you will change.
- Do not reuse an entity by `name`. Create a new entity with a new name.
- Read all IDs from tool responses. Do not use the guide placeholder IDs.
  Do not use the `$VAR=$(... | jq -r ".id")` pattern.
