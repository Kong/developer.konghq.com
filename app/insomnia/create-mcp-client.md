---
title: Create an MCP Client
content_type: reference
layout: reference
description: Connect Insomnia to an MCP Server and discover available Tools, Prompts, and Resources.
breadcrumbs:
  - /insomnia/
  - /insomnia/mcp-servers/
products:
  - insomnia
min_version:
    insomnia: '12.0'  

related_resources:
  - text: Learn more about MCP Servers
    url: /insomnia/mcp-servers/
  - text: Use mock servers
    url: /how-to/create-a-cloud-hosted-mock-server/

faqs:
  - q: What happens when authentication fails?
    a: |
      If the MCP Server responds with **401 Unauthorized**, Insomnia automatically looks for OAuth metadata and applies the **MCP Auth Flow**.  
      If no OAuth metadata is provided, you can connect manually using a **Personal Access Token (PAT)** or a registered OAuth application.
  - q: How do I refresh operations from the server?
    a: |
      - From **MCP Servers**, in the left pane, click **Resync**.  
      
      Insomnia refreshes all tools, prompts, and resources from the connected MCP Server.  
---
Use Insomnia to connect external **Model Context Protocol (MCP)** Servers to access AI-ready tools, prompts, and resource. An **MCP Client** defines this connection and stores authentication and configuration details.

## Overview

An MCP Server is an HTTP JSON-RPC endpoint that advertises callable **Tools**, available **Prompts**, and structured **Resources**. The MCP Client in Insomnia discovers these elements, which allows you to test, query, or invoke them directly within the app. Each workspace can contain multiple MCP Clients.

### Create the MCP client
To create a new MCP Client, complete the following:
1. From your Insomnia project, click **Create**.
1. In the **Name** box, type a name for the MCP Client.
1. Click **Create** 
1. To connect your MCP client to an MCP server, click **Connect**.
1. In the left pane, confirm that discovered Tools, Prompts, and Resources appear.

## Explore the interface
- In the **Right pane**, view discovered tools, resources, and prompts from the discovered MPC server. 
- In the **Middle pane**, review parameters and request fields. To send JSON requests, click **Send**.
- To see output and logs, click **Console** tab.   

## Authentication

{:.info}
> Insomnia uses your system’s default browser for OAuth sign-in.

When you connect to an MCP Server that requires authentication, Insomnia follows the **MCP Auth Flow**:

1. If the server responds with **401 Unauthorized** and includes valid metadata,  
   Insomnia automatically discovers the associated **OAuth authorization server**.
2. If your current auth method is **OAuth 2.0 → MCP Auth Flow** and it’s enabled,  
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

