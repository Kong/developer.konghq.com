{% if include.section == "question" %}

Should I create an MCP server or MCP registry in the new {{site.konnect_catalog}}?
{% elsif include.section == "answer" %}

If you're creating a new MCP definition, create an [MCP server](/catalog/mcp-servers/). 
It's the preferred object going forward, and is additive to the MCP registry's server object.
It captures remotes and packages like an MCP registry, but also supports the server's tools, resources, and prompts.
You can also [link an MCP server to {{site.ai_gateway}} 2.0](/catalog/mcp-servers/#create-an-mcp-server) as its source.

If you're already using MCP registries, we recommend manually migrating to MCP server so you can use these additional capabilities.

{% endif %}