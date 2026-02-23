---
title: MCP clients in Insomnia
content_type: reference
layout: reference
description: Learn about MCP servers in Insomnia, connect Insomnia to an MCP Server, and discover available tools, prompts, and resources.
breadcrumbs:
  - /insomnia/
products:
  - insomnia  

related_resources:
  - text: Use mock servers
    url: /how-to/create-a-cloud-hosted-mock-server/
  - text: MCP Registry in {{site.konnect_short_name}} (tech preview)
    url: /catalog/mcp-registry/

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
      Many MCP Servers expect the client to discover their authorization server first. A typical pattern is: client contacts the server > server returns **401** with metadata > client follows metadata to obtain OAuth endpoints. Some MCP Servers do not support Dynamic Client Registration (DCR); in this case, use a pre-registered client or PAT instead.
  - q: Why can’t Insomnia connect to my MCP Server?
    a: |
      The MCP Server must support the **HTTP JSON-RPC transport** protocol. If a connection fails or no resources are discovered, confirm that your server exposes a valid MCP endpoint and is online.
      If the server is temporarily unreachable, Insomnia displays cached resources until the next successful sync. 
  - q: Can I use a Personal Access Token (PAT) instead of OAuth?
    a: |
      Yes. Select **Auth > Bearer Token** and enter your PAT in the **Token** field.
  - q: Why doesn’t my browser open during OAuth sign-in?
    a: |
      The MCP Auth Flow uses your system’s default browser. Ensure that Insomnia can open URLs using your system browser. The MCP Auth Flow only supports browser-based OAuth.
  - q: Why is MCP Auth Flow not listed under OAuth 2.0?
    a: |
      The MCP Server’s metadata may not include a valid authorization endpoint. Use a **Personal Access Token (PAT)** or **Basic Auth** instead.
  - q: Can I re-test MCP authentication?
    a: |
      Yes. To re-start the **MCP Authentication Flow**, remove the existing token and reconnect:

      1. Open the **Authentication** tab.
      1. Disconnect from the server.
      1. Delete the current access token value.
      1. Reconnect or send a request to trigger the flow again.

      Insomnia only restarts the MCP Authentication Flow when the server responds with `401 Unauthorized`.

      > **Note:** You can't re-run individual MCP Auth calls. Only the full flow can be restarted manually.
  - q: What should I do if an MCP request is taking a long time to run?
    a: |
      From the **Events** tab, click the cancel icon beside the request that is currently running. This ends the current MCP task and returns control to the app.
  - q: How are MCP Clients stored in Insomnia?
    a: |
      MCP Clients are project-scoped resources and can be stored in Local, Git, and Cloud projects.
  - q: Why don’t MCP Clients appear in a Git or Cloud project after I upgrade Insomnia?
    a: |
      This can happen if the project was cloned or opened using an older version of Insomnia that did not support MCP Clients in Git or Cloud projects.

      If you cloned or opened a Git or Cloud project before upgrading to Insomnia 12.3, and that project contains MCP Client files, you must re-clone the project after upgrading. This ensures Insomnia loads the MCP Client resources correctly.

      {:.info}
      > Projects cloned or created using Insomnia 12.3 or later are not affected.     
       
---
Use Insomnia to connect external **Model Context Protocol (MCP)** Servers to access AI-ready tools, prompts, and resources. An **MCP Client** defines this connection and stores authentication and configuration details.

## Overview

An MCP Server is an HTTP JSON-RPC endpoint that advertises callable operations:
- **Tools** – Executable server functions  
- **Prompts** – Reusable prompt templates  
- **Resources** – Structured contextual data 

The Insomnia **MCP Client** discovers these elements, which enables you to invoke, query, or test them directly in the app. Each workspace can include multiple MCP Clients.

{% new_in 12.3 %} MCP Clients are project-scoped resources and can be stored in: 
- Git projects
- Cloud projects
- Local projects

This means that MCP Client configuration is saved as part of the project and can be shared, synced, and versioned in the same way as other project resources.

{:.info}
> Projects that contain MCP Clients require Insomnia 12.3 or later. If you opened or cloned a Git or Cloud project before upgrading to 12.3, re-clone the project after upgrading so Insomnia can load the MCP Client resources correctly.

### Create an MCP client
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
      Define or edit input parameters for the selected MCP operation. Each field corresponds to the parameters advertised by the server’s schema.
  - pane: "Auth"
    description: |
      Configure authentication information.
  - pane: "Headers"
    description: |
      Add or override request headers before sending a call to the server. Use for testing custom content types or authorization headers.
  - pane: "Roots"
    description: |
      Displays available endpoints or callable tools exposed by the connected MCP server. Use to select a route to load its parameters into the **Params** tab.
  - pane: "Events"
    description: |
      Displays real-time server events such as discovery updates or authentication state changes during the MCP session.
  - pane: "Notifications"
    description: |
      Lists informational or error messages returned by the MCP Server or Insomnia runtime. For example, sync success or OAuth errors.
  - pane: "Headers"
    description: |
      Shows response headers returned from the MCP Server, including status and content type. Use to verify that the response matches expected headers.
  - pane: "Console"
    description: |
      Displays detailed logs and operation results. Use this tab to inspect raw request and response payloads when troubleshooting MCP interactions.
{% endtable %}
<!-- vale on -->


## MCP Authentication

When you connect to an MCP Server that requires authentication, Insomnia follows the **MCP Auth Flow**:

1. If the server responds with **401 Unauthorized** and includes valid metadata,  
   Insomnia automatically discovers the associated **OAuth authorization server**.
2. If your current auth method is **OAuth 2.0 > MCP Auth Flow** and it’s enabled,  
   Insomnia requests a token through that flow.
3. If it’s not selected, Insomnia prompts you to switch to the discovered auth flow.  
   Confirm to proceed or cancel to remain on your current method.

{:.info}
> Not all MCP-compatible servers handle authentication the same way. Because this standard evolves quickly, some setups may need manual tweaks to work as expected. Insomnia shows you every request and response so you can check what succeeded or failed.

If the authorization server does not support Dynamic Client Registration, you can:
- Use a **Personal Access Token (PAT)**, for example GitHub Copilot MCP Server.  
- Register your own **OAuth application**, then enter the Client ID and Secret in Insomnia.

## Elicitation responses

Insomnia supports **MCP Elicitation**, a feature that allows a server to request additional information from the client during a request. When a server returns an elicitation request, Insomnia displays the fields defined by the server so you can provide the required information. Insomnia then returns the submitted values to the server so it can continue processing the original request.

Elicitation supports workflows where the server needs more context or specific field values before it completes an action. Insomnia manages the entire flow: 
1. Displays the elicitation UI
1. Collects the user input
1. Returns the elicitation response to the server

### How Elicitation works

1. The MCP server returns an **elicitation request** while handling an operation.  
1. Insomnia displays an **Elicitation Form** in the response pane based on the fields defined in the request.  
1. User enters the requested information.  
1. Insomnia sends an **elicitation response** that contains the submitted values back to the server.  
1. The server continues processing using the new information.

For more details, see the MCP client specification for [elicitation](https://modelcontextprotocol.io/specification/draft/client/elicitation)

## Sampling responses

Insomnia supports **MCP Sampling**. Sampling is a workflow where an MCP server requests Insomnia to generate a model response based on the current context. Insomnia then uses its AI integration to produce the sampling response, and it presents the request and response steps in a dedicated interface in the Response pane.

### How sampling works

1. The MCP server issues a `sampling/createMessage` request to the Insomnia MCP client.
1. Insomnia displays the sampling request in the Response pane so that the user can review and modify it before generation.
1. After the user approves the request, Insomnia forwards it to the model that's using Insomnia AI.
1. Insomnia receives the model’s output and then displays the response so that the user can review and modify it.
1. After the user approves the response, Insomnia then returns the final result to the MCP server. 

{:.info}
> When supported by the server, this process can continue across additional turns.

For more information about sampling, go to the MCP [Sampling](https://modelcontextprotocol.io/specification/draft/client/sampling) documentation.
