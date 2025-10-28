---
title: MCP clients in Insomnia
content_type: reference
layout: reference
description: Learn about MCP servers in Insomnia, connect Insomnia to an MCP Server, and discover available Tools, Prompts, and Resources.
breadcrumbs:
  - /insomnia/
products:
  - insomnia
min_version:
    insomnia: '12.0'  

related_resources:
  - text: Use mock servers
    url: /how-to/create-a-cloud-hosted-mock-server/
  - text: "Introducing Model Context Protocol in Insomnia (Blog)"
    url: https://mcp.deepwiki.com/mcp  

faqs:
  - q: What happens when authentication fails?
    a: |
      If the MCP Server responds with **401 Unauthorized**, Insomnia automatically looks for OAuth metadata and applies the **MCP Auth Flow**.  
      If no OAuth metadata is provided, you can connect manually using a **Personal Access Token (PAT)** or a registered OAuth application.
  - q: How do I refresh operations from the server?
    a: |
      - From **MCP Servers**, in the left pane, click **Resync**.  
      
      Insomnia refreshes all tools, prompts, and resources from the connected MCP Server.
  - q: How do I refresh operations from the server?
    a: |
      - From **MCP Servers** in the left pane, click **Resync**.  
      Insomnia refreshes all Tools, Prompts, and Resources from the connected MCP Server.
  - q: Why do I see **401 Unauthorized** during MCP discovery?
    a: |
      Many MCP Servers expect the client to discover their authorization server first.  
      A typical pattern is: client contacts the server > server returns **401** with metadata > client follows metadata to obtain OAuth endpoints.  
      If the provider doesn’t support Dynamic Client Registration (DCR), then automatic registration fails. Use a pre-registered client or a PAT.
  - q: Can I use a Personal Access Token (PAT) instead of OAuth?
    a: |
      Yes. Select **Auth > Bearer Token** and enter your PAT in the **Token** field.
  - q: Does GitHub’s remote MCP Server support Dynamic Client Registration?
    a: No. GitHub’s MCP Server does not support DCR. Use a pre-registered client or PAT instead.
  - q: Why doesn’t my browser open during OAuth sign-in?
    a: |
      The MCP Auth Flow uses your system’s default browser. Ensure that Insomnia can open URLs using your system browser. The MCP Auth Flow only supports browser-based OAuth.
  - q: Why is MCP Auth Flow not listed under OAuth 2.0?
    a: |
      The MCP Server’s metadata may not include a valid authorization endpoint. Use a **Personal Access Token (PAT)** or **Basic Auth** instead.     
---
Use Insomnia to connect external **Model Context Protocol (MCP)** Servers to access AI-ready tools, prompts, and resource. An **MCP Client** defines this connection and stores authentication and configuration details.

## Overview

An MCP Server is an HTTP JSON-RPC endpoint that advertises callable operations:
- **Tools** – Executable server functions  
- **Prompts** – Reusable prompt templates  
- **Resources** – Structured contextual data 

The Insomnia **MCP Client** discovers these elements, which enables you to invoke, query, or test them directly in the app. Each workspace can include multiple MCP Clients.

### Create a MCP client
To create a new MCP Client:
1. From the left pane of the Insomnia application, click **MCP Clients**.
1. In the **Name** box, type a name for the MCP Client.
1. Click **Create**.
1. In the **MCP Server URL** box, enter the full endpoint of your target server. For example:  
   - `https://mcp.deepwiki.com/mcp` (DeepWiki)  
1. To connect your MCP client to the MCP server, click **Connect**.
1. (Optional) If the server requires authentication, follow the **MCP Auth Flow** to sign in or provide a token.  
1. Once connected, in the left pane, confirm that discovered tools, prompts, and resources appear.


## Explore the interface

The MCP Client interface in Insomnia provides multiple panes that display operations, parameters, and runtime details from connected MCP Servers.

Use these panes to inspect discovered endpoints, configure request parameters, and validate outputs in real time.

<!-- vale off -->
{% table %}
columns:
  - title: Tab
    key: pane
  - title: Description
    key: description
rows:
  - pane: "Params"
    description: |
      Define or edit input parameters for the selected MCP operation. Each field corresponds to the parameters advertised by the server’s JSON-RPC schema.
  - pane: "Auth"
    description: |
      Configure authentication for requests.
  - pane: "Headers"
    description: |
      Add or override request headers before sending a call to the server. Use for testing custom content types or authorization headers.
  - pane: "Routes"
    description: |
      Displays available endpoints or callable tools exposed by the connected MCP Server. Use to select a route to load its parameters into the **Params** tab.
  - pane: "Parameter Builder"
    description: |
      Auto-generate structured JSON payloads based on the selected operation’s input schema. Use to access an assisted form view for complex nested parameters.
  - pane: "Parameter Overview"
    description: |
      Displays all defined parameters in read-only mode for quick validation before sending a request.
  - pane: "Events"
    description: |
      Displays real-time server events such as discovery updates or authentication state changes during the MCP session.
  - pane: "Notifications"
    description: |
      Lists informational or error messages returned by the MCP Server or Insomnia runtime. For example, sync success or OAuth errors.
  - pane: "Headers"
    description: |
      Shows response headers returned from the MCP Server, including status and content type. Use to verify that the response matches expected metadata.
  - pane: "Console"
    description: |
      Displays detailed JSON-RPC logs and operation results. Use this tab to inspect raw request and response payloads when troubleshooting MCP interactions.
{% endtable %}
<!-- vale on -->


## Authentication

{:.info}
> Insomnia uses your system’s default browser for OAuth sign-in.

When you connect to an MCP Server that requires authentication, Insomnia follows the **MCP Auth Flow**:

1. If the server responds with **401 Unauthorized** and includes valid metadata,  
   Insomnia automatically discovers the associated **OAuth authorization server**.
2. If your current auth method is **OAuth 2.0 > MCP Auth Flow** and it’s enabled,  
   Insomnia requests a token through that flow.
3. If it’s not selected, Insomnia prompts you to switch to the discovered auth flow.  
   Confirm to proceed or cancel to remain on your current method.

If the authorization server does not support [Dynamic Client Registration](/dev-portal/dynamic-client-registration/), you can:
- Use a **Personal Access Token (PAT)**, for example GitHub Copilot MCP Server.  
- Register your own **OAuth application**, then enter the Client ID and Secret in Insomnia.

## Manage requests and authentication
1. To add required parameters, click the **Params** tab.   
2. To configure authentication credentials, click the **Auth** tab.  
3. Click **Save**.  
4. Confirm that parameters and credentials are stored correctly.

## Limitations and considerations

- MCP Servers must support **HTTP JSON-RPC transport**.  
- Dynamic Client Registration is optional and not universally supported.  
- If an MCP Server is unreachable, Insomnia displays cached resources until the next sync.  

