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
        No, MCP Registries in {{site.konnect_catalog}} is only available in Tech Preview via {{site.konnect_short_name}} Labs.

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

This feature is built on top of the MCP Registry API specification defined by {{ site.anthropic }}’s [open source project](https://github.com/modelcontextprotocol/registry/blob/main/docs/reference/api/openapi.yaml). The specification allows flexibility in how registries are structured, so you can model them according to your organization’s governance needs.


## Enable MCP Registries in {{site.konnect_catalog}}

MCP Registries in {{site.konnect_catalog}} are currently available in tech preview via {{site.konnect_short_name}} Labs.

1. In {{site.konnect_short_name}}, click your organization dropdown and select "Manage organizations".
1. Click the **Labs** tab.
1. Click **Catalog - MCP Registry**.
1. Click **Enable feature**.

You can access MCP Registries by doing the following:

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **MCP registries** tab.
   {:.info}
   > If you're using [{{site.konnect_catalog}} Classic](/catalog-classic/), click **MCP Registries** in the sidebar instead.

## Create an MCP Registry

{% navtabs "create-mcp-registry" %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **MCP registries** tab.
   
   {:.info}
   > If you're using [{{site.konnect_catalog}} Classic](/catalog-classic/), click **MCP Registries** in the sidebar instead.
1. From the **New** dropdown menu, select "MCP registry".
1. In the **Display Name** field, enter a name for your registry, for example `Production Registry`.
1. In the **Name** field, enter a unique identifier for the registry, for example `production-registry`. This must be lowercase and alphanumeric, and can include hyphens.
1. (Optional) In the **Description** field, describe the purpose of this registry.
1. Click **Create**.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a POST request to the `/mcp-registries` endpoint:

```sh
curl -X POST "https://klabs.us.api.konghq.com/v0/mcp-registries" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  --json '{
    "name": "internal-mcp-registry",
    "display_name": "Internal MCP Registry",
    "description": "Registry for MCP servers approved for internal AI agents"
  }'
```
{% endnavtab %}
{% endnavtabs %}

## Add an MCP server

An MCP server represents an agent-facing service definition. It describes:

* What the server does  
* Its version  
* How agents can connect to it

{% navtabs "publish-mcp-server" %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **MCP registries** tab.
1. Click your MCP registry.
1. From your MCP Registry's detail page, click **New MCP Server**.
1. (Optional) In the **Title** field, enter a short, descriptive name for the server, for example `Filesystem Server`.
1. In the **Name** field, enter a unique identifier in reverse-DNS format, for example `io.example/filesystem`. This must contain exactly one forward slash.
1. In the **Version** field, enter a version number using semantic versioning, for example `1.0.0`.
1. In the **Description** field, enter a description of what the server does.
1. (Optional) Click **Show optional fields**, and do the following:
   1. (Optional) In the **Schema URI** field, enter a URI, for example `https://example.com/schemas/server.json`.
   1. (Optional) In the **GitHub repository URL** field, enter a URL, for example `https://github.com/owner/repo`.
   1. (Optional) In the **Website URL** field, enter a URL, for example `https://example.com`.
   1. (Optional) In the **Metadata** field, enter a JSON object, for example `{"license": "MIT", "author": "Example Corp", "certified": true}`.
1. (Optional) To describe a run-it-yourself distribution option, such as an npm or PyPI package, click **Add Package** and do the following:
   1. From the **Transport type** dropdown menu, select an option. 
      If you select "Streamable-HTTP" or "SSE", also enter the transport URL.
   1. From the **Registry type** dropdown menu, select how you want users to download packages.
   1. In the **Registry base URL** field, enter `https://registry.npmjs.org`.
   1. In the **Package identifier** field, enter the base URL of the package registry, for example `@modelcontextprotocol/mcp-server`.
   1. (Optional) In the **Package version** field, enter a version, for example `1.0.0`.
   1. Click **Save**.
1. (Optional) To add a remote to describe a hosted MCP server endpoint that agents can connect to over the network, click **Add Remote** and do the following:
   1. From the **Transport type** dropdown menu, select "Streamable-HTTP" or "SSE".
   1. In the **Remote URL** field, enter the MCP server's endpoint, for example `https://example.com/mcp`.
   1. (Optional) In the **Headers** field, enter headers as a JSON array of objects, for example, to pass an authorization token:
   ```json
   [
     {
       "name": "Authorization",
       "value": "Bearer ${token}"
     }
   ]
   ```
   1. Click **Save**.
1. Click **Publish**.
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} API" %}
To add an MCP server, send a POST request to the `/mcp-registries/{registryIdentifier}/v0.1/publish` endpoint:

```sh
curl -X POST "https://klabs.us.api.konghq.com/v0/mcp-registries/internal-mcp-registry/v0.1/publish" \
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
{% endnavtab %}
{% endnavtabs %}


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

{% comment %}
## Publish an MCP Registry to Dev Portal

You can publish an MCP Registry to a Dev Portal to expose it to a broader audience.

1. In the {{site.konnect_short_name}} sidebar, click **Catalog**.
1. Click the **MCP registries** tab.
1. Click your MCP registry.
1. Click **Publish to portal**.
1. From the **Portal** dropdown menu, select the {{site.dev_portal}} you want to publish to.
1. Click **Publish MCP registry**.
{% endcomment %}

## Access and authentication

Registry endpoints assume a {{site.konnect_short_name}} authentication context. Only authenticated clients with appropriate [access tokens](/konnect-api/#konnect-api-authentication) can query the registry URL:

```sh
curl -X GET "https://klabs.us.api.konghq.com/v0/mcp-registries/internal-mcp-registry/v0.1/servers" \
  -H "Authorization: Bearer $KONNECT_TOKEN"
```

## What’s next

We are continuing to evolve MCP Registries alongside the broader MCP ecosystem.

Planned enhancements include:

* Linking {{site.konnect_catalog}} MCP servers to MCP servers created in {{site.ai_gateway}}
* Additional governance and lifecycle controls

Because the MCP specification is still evolving, we are committed to iterating in partnership with customers who have already begun developing MCP servers and experimenting with agent-based workflows.
