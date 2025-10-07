---
title: Create an MCP Client
content_type: how_to
description: Connect Insomnia to an MCP Server and discover available Tools, Prompts, and Resources.
breadcrumbs:
  - /insomnia/
  - /insomnia/mcp-servers/
products:
  - insomnia
prereqs:
  inline:
    - title: "MCP Server URL"
      content: |
        You must have an MCP Server ready, and supportive of **HTTP JSON-RPC transport**.

tldr:
  q: How do I create an MCP Client in Insomnia?
  a: From the Create menu, select **MCP Client**, enter your server URL, and click **Discover** to fetch Tools, Prompts, and Resources from the MCP Server.  
---

# Create an MCP Client

Use this guide to connect Insomnia to an MCP Server and explore its Tools, Prompts, and Resources.

---

## Create the client
Configure Insomnia to contact the MCP Server and list all available Tools, Prompts, and Resources:
1. From the **Create menu**, select **MCP Client**.  
2. Enter the **Server URL**.  
3. Click **Discover**.

---

## Explore the interface
- **Left pane:** lists discovered elements.  
- **Middle pane:** shows parameters and request body fields.  
- **Right pane:** provides **Preview** and **Console** tabs.  

---

## Step 3: Handle authentication automatically

When you connect to an MCP Server that requires authentication, Insomnia follows the **MCP Auth Flow**:

1. If the server responds with **401 Unauthorized** and includes valid metadata,  
   Insomnia automatically discovers the associated **OAuth authorization server**.
2. If your current auth method is **OAuth 2.0 → MCP Auth Flow** and it’s enabled,  
   Insomnia requests a token through that flow.
3. If it’s not selected, Insomnia prompts you to switch to the discovered auth flow.  
   Confirm to proceed or cancel to remain on your current method.

If the authorization server **does not support Dynamic Client Registration**, you can:
- Use a **Personal Access Token (PAT)**, for example GitHub Copilot MCP Server.  
- Register your own **OAuth application**, then enter its Client ID and Secret in Insomnia.

> **Note:** Currently, Insomnia uses your system’s default browser for OAuth sign-in.

---

## Manage parameters and auth
- Use the **Params** tab to enter required values.  
- Use the **Body** tab for JSON payloads.  
- Use the **Auth** tab if the server requires authentication.

---

## Resync the client
Use **Resync** anytime to fetch updated operations from the server.  
MCP Clients always treat the server as the source of truth.

---

## (Optional) Deactivate AI features
If AI-assisted actions appear in your workspace and you want to turn them off:
1. Go to **Preferences → AI Features**.  
2. Clear the checkboxes for **Mock Servers – Auto Generate with Natural Language** or **Git – Recommend Commits & Comments**.  
3. Locked options indicate org-level restrictions.

---

## Next steps
- [Learn more about MCP Servers](/insomnia/mcp-servers/)  
- [Use mock servers with natural language](/how-to/create-a-cloud-hosted-mock-server/)
