---
title: Troubleshoot MCP authentication
content_type: how_to
description: Resolve authentication errors when connecting to an MCP Server that doesn't support Dynamic Client Registration.
breadcrumbs:
  - /insomnia/
  - /insomnia/mcp-servers/
products:
  - insomnia
next_steps:
  - text: Create an MCP Client
    url: /how-to/create-mcp-client/

tldr:
  q: How do I fix authentication errors when connecting to an MCP Server?
  a: If the MCP Auth Flow fails because the server doesn’t support Dynamic Client Registration, use a Personal Access Token or register your own OAuth app and enter its Client ID and Secret in Insomnia.
---

# Troubleshoot MCP authentication

When connecting to an **MCP Server**, Insomnia uses the **MCP Auth Flow** to obtain tokens automatically through OAuth 2.0.  
If the server doesn't support [**Dynamic Client Registration**](/dev-portal/dynamic-client-registration/), you must configure the authentication manually.

---

## Symptoms

You might see one of the following when connecting:

- **401 Unauthorized** after discovery  
- Dialog message: *“Dynamic Client Registration not supported by this authorization server.”*  
- Failed token exchange or missing redirect to your system browser  

---

## Verify the server supports OAuth 2.0

1. In Insomnia, open the **Auth** tab for your MCP Client.  
2. Check the **Authorization Type** list for **OAuth 2.0 → MCP Auth Flow**.  
3. If it’s missing, your server may only support personal tokens or basic authentication.  
4. (Optional) Check the server’s metadata for an `authorization_endpoint` and `token_endpoint`.

---

## Use a Personal Access Token (PAT)

If the server doesn’t implement OAuth 2.0 at all, or if Dynamic Client Registration fails:

1. Generate a **Personal Access Token** (PAT) from the service that hosts your MCP Server.  
2. In Insomnia, open **Auth → Bearer Token**.  
3. Paste the PAT into the token field.  
4. Retry the discovery or request.

---

## Register your own OAuth app

If the authorization server supports OAuth 2.0 but not Dynamic Client Registration:

1. Create an **OAuth application** on the provider’s developer portal.  
2. Set the redirect URI to: `http://localhost:<random_port>/callback`.
Insomnia opens this callback URL automatically in your system browser.  
3. Copy the **Client ID** and **Client Secret** into Insomnia:  
- Go to **Auth → OAuth 2.0 → Custom OAuth**.  
- Enter your credentials and select **Use system browser**.  
4. Click **Get Token** to sign in.

---

## Review security settings

- Avoid using fallback clients that expose credentials in source code.  
- Store PATs or OAuth secrets securely; Insomnia keeps them encrypted on disk.  
- Rotate tokens periodically to prevent unauthorized reuse.

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