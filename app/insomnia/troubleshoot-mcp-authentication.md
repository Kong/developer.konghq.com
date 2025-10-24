---
title: Troubleshoot MCP authentication
content_type: reference
layout: reference
description: Diagnose and resolve authentication errors when connecting Insomnia to MCP servers that don’t support OAuth Dynamic Client Registration.
breadcrumbs:
  - /insomnia/
  - /insomnia/mcp-servers/
products:
  - insomnia
min_version:
    insomnia: '12.0'  
related_resources:
  - text: Create an MCP Client
    url: /how-to/create-mcp-client/
faqs:
  - q: Why do I see **401 Unauthorized** during MCP discovery?
    a: |
      Many MCP servers expect the client to discover their authorization server first. A typical flow is: client accesses server → server returns **401** with metadata → client follows metadata to get OAuth endpoints. If the provider doesn’t support Dynamic Client Registration, automatic registration fails and you must use a pre-registered client or a personal token. :contentReference[oaicite:7]{index=7}
  - q: Can I use a Personal Access Token (PAT) instead of OAuth?
    a: |
      Yes. Insomnia supports sending requests with **Bearer token** auth. If your MCP server documents PAT usage, set **Auth → Bearer token** and provide the token. :contentReference[oaicite:8]{index=8}
  - q: Does GitHub’s remote MCP server support Dynamic Client Registration?
    a: |
      Not currently. The GitHub remote MCP server issue tracker states DCR isn’t supported yet; use a pre-registered client or a PAT per server documentation. :contentReference[oaicite:9]{index=9}
---
When you connect Insomnia to a Model Context Protocol (MCP) server, the MCP client may need to obtain credentials from OAuth before listing tools, prompts, or resources. If the authorization server doesn’t support [**Dynamic Client Registration (DCR)**](/dev-portal/dynamic-client-registration/), the automatic [MCP Auth Flow](insomnia/create-mcp-client/#authentication-flow) can’t register a client on your behalf. This means that you’ll need to supply credentials manually, for example, a PAT.

- **MCP overview:** MCP standardizes how clients connect to external systems to access tools and structured context. Servers expose capabilities, and clients discover and invoke them. For example, tools with JSON-schema inputs.

- **Typical MCP OAuth flow:** A common pattern is: client contacts the MCP server → server returns **401** with metadata → client fetches authorization endpoints and requests a token. If the provider **doesn’t** support DCR, the client can’t auto-register and must use a pre-registered OAuth client or another auth method.

---
## Common causes and resolutions
<!-- vale off -->
{% table %}
columns:
- title: Issue
  key: issue
- title: Resolution
  key: resolution
rows:
- issue: Authorization server returns an invalid client response
  resolution: |
   Check that the Client ID and Client Secret are correct, and that the redirect URI matches your app settings.
- issue: Browser does not open during OAuth flow
  resolution: |
   Ensure that Insomnia can open URLs with your system default browser. The MCP Auth Flow currently supports browser-based OAuth only.
- issue: Token obtained but requests still fail with **401 Unauthorized**
  resolution: |
   The MCP Server may require additional scopes. Update scopes in **Auth → OAuth 2.0 → Scope**.
- issue: MCP Auth Flow not listed under OAuth 2.0
  resolution: |
   The server metadata didn’t include a valid authorization endpoint. Use a PAT or Basic Auth instead.
{% endtable %}
<!-- vale on -->
---

## Symptoms

You might encounter:
- During discovery, **401 Unauthorized** responses  
- An error indicating that **Dynamic Client Registration** isn’t supported  
- Successful token issuance elsewhere, but requests from the MCP client still fail

{:.info}
> Many providers don’t support DCR for their OAuth servers, which explains these failures.

---

## Resolutions

### Verify that the server supports OAuth 2.0

1. From the MCP Servers window, in the middle pane, click the **Auth** tab.  
2. Check the **Authorization Type** list for **OAuth 2.0 → MCP Auth Flow**.  
3. If it’s missing, your server may only support personal tokens or basic authentication.  
4. (Optional) Check the server’s metadata for an `authorization_endpoint` and `token_endpoint`.

If the option is not present, your server may only support PAT/Bearer token or basic authentication. For more information, go to [Request authentication](/insomnia/request-authentication/).

### Use a Personal Access Token (PAT)

If the server doesn’t implement OAuth 2.0 at all, or if DCR fails:

1. Generate a **Personal Access Token** (PAT) from the service that hosts your MCP Server.  
2. In Insomnia, open **Auth → Bearer Token**.  
3. In the **Token** field, enter your PAT.  
4. Retry the discovery or request.

### Use OAuth 2.0 with a pre-registered client (no DCR)

If the Authorization Server supports OAuth 2.0 but not DCR, the **Insomnia MCP Client** cannot auto-register during the MCP Auth Flow. Use credentials from an OAuth client that your Identity Provider (IdP) has already registered for your **MCP Server**.

**IdP configuration (outside Insomnia):**
- Register an OAuth 2.0 client in your IdP’s developer portal for the MCP Server.
- Use the redirect URI your IdP requires for desktop/app flows.  

Insomnia completes the OAuth flow in your system browser.

**Insomnia UI (secondary):**
1. In the **Auth** tab, select **OAuth 2.0 → Custom OAuth**.
2. In the **Client ID** field, enter your IdP client ID.
3. In the **Client Secret** field, enter your IdP client secret.
4. Select **Use system browser**.
5. Click **Get Token**.

---

## Review security settings

- Avoid using fallback clients that expose credentials in source code.  
- Store PATs or OAuth secrets securely; Insomnia keeps them encrypted on disk.  
- Rotate tokens periodically to prevent unauthorized reuse.
---