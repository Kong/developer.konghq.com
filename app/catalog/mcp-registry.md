---
title: "MCP Registries in {{site.konnect_catalog}}"
content_type: reference
layout: reference
tech_preview: true
products:
    - catalog
works_on:
  - konnect

description: An MCP Registry is a centralized publishing and discovery endpoint for MCP servers within your organization. Learn how to register your MCP servers in {{site.konnect_short_name}} {{site.konnect_catalog}}.

breadcrumbs:
  - /catalog/
search_aliases:
  - service catalog
  - mcp
related_resources:
  - text: "{{site.konnect_catalog}}"
    url: /catalog/
  - text: "MCP traffic gateway"
    url: /mcp/
  - text: "MCP clients in Insomnia"
    url: /insomnia/mcp-clients-in-insomnia/
faqs:
    - q: Is the MCP Registry feature GA?
      a: |
        No, MCP Registries in Catalog is only available in Tech Preview via {{site.konnect_short_name}} Labs.

        This feature is built on top of Anthropic’s MCP Registry API specification, which is still rapidly evolving. Because the underlying standard continues to change, we cannot responsibly commit to GA timelines or long-term stability guarantees at this time.

        We are actively iterating in partnership with customers who are exploring MCP-based agent architectures and will evaluate GA readiness as the specification matures.
---

## What is an MCP Registry?

An MCP Registry is a centralized publishing and discovery endpoint for MCP servers within your organization.

As organizations experiment with AI agents, MCP servers are often embedded directly into agent code, stored in local configuration files, or scattered across repositories. Over time, this can lead to MCP sprawl, making it difficult to understand:

* What MCP servers exist  
* Which agents should use which servers  
* How those servers should be governed

MCP Registries extend {{site.konnect_short_name}} {{site.konnect_catalog}} to provide a structured, standards-based way to register and manage MCP servers, helping Platform Teams maintain visibility and control as AI adoption scales.

This feature is built on top of the MCP Registry API specification defined by Anthropic’s [open source project](https://github.com/modelcontextprotocol/registry/blob/main/docs/reference/api/openapi.yaml). The specification allows flexibility in how registries are structured, so you can model them according to your organization’s governance needs.


## Enable MCP Registries in {{site.konnect_catalog}}

MCP Registries in {{site.konnect_catalog}} is currently available in tech preview via {{site.konnect_short_name}} Labs.

1. In the {{site.konnect_short_name}} sidebar, navigate to **Organizations**.
1. In the Organization sidebar, click **Labs**.
1. Click **Catalog - MCP Registry**.
1. Click the toggle at the top right to enable the integration.

You can access the MCP Registry by navigating to **Catalog** > **MCP Registries** in the sidebar.

## Create an MCP Registry

Send a POST request to the `/registries` endpoint:

```sh
curl -X POST "https://klabs.us.api.konghq.com/v0/registries" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  --json '{
    "name": "internal-mcp-registry",
    "display_name": "Internal MCP Registry",
    "description": "Registry for MCP servers approved for internal AI agents"
  }'
```

## Publish an MCP server

An MCP server represents an agent-facing service definition. It describes:

* What the server does  
* Its version  
* How agents can connect to it

To add an MCP server, send a POST request to the `/registries/{registryIdentifier}/v0.1/publish` endpoint:

```sh
curl -X POST "https://klabs.us.api.konghq.com/v0/registries/internal-mcp-registry/v0.1/publish" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  --json '{
    "name": "com.example/expense-reimbursement",
    "description": "MCP server that allows agents to submit expense reports and check reimbursement status.",
    "version": "1.0.0",
    "packages": [
      {
        "registryType": "npm",
        "identifier": "@example/expense-reimbursement-mcp",
        "version": "1.0.0",
        "transport": {
          "type": "stdio"
        }
      }
    ],
    "remotes": [
      {
        "type": "streamable-http",
        "url": "https://mcp.internal.example.com/expense"
      }
    ]
  }'
```


## Packages and remotes

MCP servers are defined independently from a single deployment. They may include multiple delivery paths.

### Packages

Packages describe run-it-yourself distribution options, such as:

* npm packages  
* PyPI packages  
* OCI artifacts

These allow teams to install and run the MCP server within their own agent environments.

### Remotes

Remotes describe hosted MCP server endpoints that agents can connect to over the network, such as:

* streamable-http  
* sse

An MCP server can define multiple packages and multiple remotes simultaneously. This allows organizations to support different runtime environments without duplicating server definitions.


## Access and authentication

Today, registry endpoints assume a {{site.konnect_short_name}} authentication context. Only authenticated clients with appropriate access tokens can query the registry URL:

```sh
curl -X GET "https://klabs.us.api.konghq.com/v0/registries/internal-mcp-registry/v0.1/servers" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```

Future enhancements will allow MCP servers to be published to Dev Portal, enabling controlled exposure to broader audiences, including users and agents outside of {{site.konnect_short_name}}.


## What’s next

We are continuing to evolve MCP Registries alongside the broader MCP ecosystem.

Planned enhancements include:

* Publishing MCP servers to Dev Portal  
* Auto-registration of MCP servers created via {{site.konnect_short_name}}-native workflows such as {{site.ai_gateway}} 
* Additional governance and lifecycle controls

Because the MCP specification is still evolving, we are committed to iterating in partnership with customers who have already begun developing MCP servers and experimenting with agent-based workflows.
