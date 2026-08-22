---
title: "Dev Portal MCP server"
content_type: reference
layout: reference

products:
  - dev-portal

tags:
  - mcp
  - application-registration
  - authentication

works_on:
  - konnect

breadcrumbs:
  - /dev-portal/

description: "Learn how {{site.dev_portal}} exposes published APIs to AI agents as an MCP server, and how its settings control what agents can read and do."

related_resources:
  - text: About Dev Portal
    url: /dev-portal/
  - text: Developer self-service and application registration
    url: /dev-portal/self-service/
  - text: Application authentication strategies
    url: /dev-portal/auth-strategies/
  - text: MCP overview
    url: /mcp/

faqs:
  - q: What's the difference between the AI settings toggle and the MCP server toggle for {{site.dev_portal}}?
    a: |
      These are two separate settings, each configured in {{site.dev_portal}}:
      * **AI settings only**: Developers can open a published API's documentation directly in a supported LLM client to read it. This doesn't create an MCP server or give an agent tool access to {{site.dev_portal}}.
      * **AI settings and MCP server enabled**: Developers can additionally connect an agent to {{site.dev_portal}}'s MCP server, giving the agent tool access to browse and (depending on configuration) act on published content, scoped to what that developer can already see.
  - q: Do agents need to log in to use a Dev Portal MCP server?
    a: |
      It depends on whether {{site.dev_portal}} login is enabled, not just on the MCP server or AI settings toggles:
      * If {{site.dev_portal}} login is disabled, the MCP server serves public content without any authentication step.
      * If {{site.dev_portal}} login is enabled, the developer must log in and authorize the connection before the agent can access **any** content through the MCP server, including content that would otherwise be public. There's no combination of settings that allows an agent to skip this step while {{site.dev_portal}} login is on.

      Authorizing the connection only authenticates the agent's MCP session, it doesn't hand over API credentials. If the agent needs to actually call the APIs it discovers (not just read their documentation), the developer must still separately generate the application's credentials and share them with the agent.
--- 

{{site.dev_portal}} can expose the APIs, pages, and documentation published to it as an MCP server, so AI agents can browse and use them on behalf of a developer. 
The {{site.dev_portal}} MCP server respects the same authentication and access control that applies to the developer using it.
This MCP server is separate from [{{site.ai_gateway}}'s MCP capabilities](/mcp/), which convert a Gateway API into an MCP server directly. 

As you publish new APIs, pages, and documentation to your {{site.dev_portal}}, the {{site.dev_portal}} MCP server will always be automatically up-to-date with your latest changes.

## How it works

A {{site.dev_portal}} MCP server can work in one of three modes:
* **Public read-only**: If {{site.dev_portal}} login is disabled, the MCP server exposes public content to any agent, with no authentication step.
* **Authenticated read-only**: If {{site.dev_portal}} login is enabled and write operations are disabled, a developer must authenticate and authorize the connection before their agent can browse anything, but the agent can only read what's already published.
* **Authenticated read-write**: If {{site.dev_portal}} login is enabled and write operations are also enabled, an authenticated agent can additionally create and manage applications and register APIs to them on the developer's behalf.

An agent can only see what its developer can already see. If [RBAC](/dev-portal/developer-rbac/) or [visibility settings](/dev-portal/pages-and-content/#page-visibility-and-publishing) restrict a developer from a page, API, or specification, the MCP server doesn't expose it to that developer's agent either.
Conversely, if a developer _can_ access a restricted page, the MCP server will also expose it to their agent.

When write operations are enabled, an agent can handle the administrative side of application registration: creating an application, registering APIs to it, and updating it. 
Agents can never generate application's credentials themselves. 
A developer must always create the application's credentials, then share them with the agent separately if the agent needs to actually call the APIs it discovers.

How much of {{site.dev_portal}}'s content an agent can reach, and whether it needs to authenticate first, depends on {{site.dev_portal}} login combined with the {{site.dev_portal}} AI settings:

<!--vale off-->
{% table %}
columns:
  - title: "{{site.dev_portal}} login"
    key: login
  - title: MCP server
    key: mcp
  - title: Write operations
    key: write
  - title: What an agent can do
    key: outcome
rows:
  - login: Disabled
    mcp: Enabled
    write: N/A
    outcome: |
      Read-only access to {{site.dev_portal}}'s public pages, APIs, and specifications. No authentication step is required to connect.
  - login: Enabled
    mcp: Enabled
    write: Disabled
    outcome: |
      The agent must authenticate before it can access anything through the MCP server, including public content. After it's connected, it can read whatever its developer can see.
  - login: Enabled
    mcp: Enabled
    write: Enabled
    outcome: |
      The agent must authenticate before it can access anything through the MCP server, including public content. 
      After it's connected, it can read whatever its developer can see. 
      The agent can also create, read, and update applications and register APIs to them on the developer's behalf. 
      A human must still generate the application's credentials.
{% endtable %}
<!--vale on-->

## Generate an MCP server from {{site.dev_portal}}

There are two settings you can use to manage AI settings on your {{site.dev_portal}}:
* **Only AI settings enabled:** When just the AI settings are enabled, this displays an option to open an API in Claude or ChatGPT. Some LLMs will block this if you aren't using a custom {{site.dev_portal}} domain because bots aren't allowed on `*.kongportals.com` domains.
* **AI settings and MCP server are enabled:** This also displays the option to open the API in Claude or ChatGPT, but also allows developers to connect to the MCP server via URL, VS Code, or Cursor. 

You can also optionally enable write operations to let agents manage applications on a developer's behalf.

{% navtabs "enable-mcp-server" %}
{% navtab "{{site.konnect_short_name}} API" %}
Send a PATCH request to the [`/portals/{portalId}/ai-settings` endpoint](/api/konnect/portal-management/v3/#/operations/update-ai-settings):
<!--vale off-->
{% konnect_api_request %}
url: /v3/portals/$DEV_PORTAL_ID/ai-settings
method: PATCH
status_code: 200
body:
  enabled: true
  features:
    mcp_server:
      enabled: true
{% endkonnect_api_request %}
<!--vale on-->

You can enable just the AI settings by omitting `features` parameters. 
{% endnavtab %}
{% navtab "{{site.konnect_short_name}} UI" %}
1. In the {{site.konnect_short_name}} sidebar, expand **Dev Portal** and click **Portals**.
1. Click your {{site.dev_portal}}.
1. Click the **Settings** tab.
1. Click the **AI Settings** tab.
1. Enable **AI Settings**.
1. Enable **MCP Server**.
1. Click **Save changes**.
{% endnavtab %}
{% endnavtabs %}

## Connect an agent to a {{site.dev_portal}} MCP server

Once an admin enables the MCP server for {{site.dev_portal}}, a developer connects their own agent or IDE to it from their {{site.dev_portal}} account:

1. Log in to {{site.dev_portal}} (required whenever {{site.dev_portal}} login is enabled).
1. Connect in one of the two following ways:
   * Connect directly from an individual API's dropdown menu. This includes options like **Copy MCP server**, **Connect to Cursor**, and **Connect to VS Code**, scoped to just that API.
   * Go to your profile menu and click **Account**. Click **About connections**. This shows two ways to connect, depending on your MCP client:
     * **OAuth 2.0**: This is for clients that support automatic discovery. Add {{site.dev_portal}}'s MCP server to the client, and it fetches {{site.dev_portal}}'s OAuth protected resource metadata, discovers the authorization server's endpoints, and starts an OAuth 2.0 Authorization Code flow with PKCE. 
     * **MCP Server**: This is for clients that need a direct URL, such as Claude Desktop custom connectors. Copy the MCP server URL (for example, `https://<your-dev-portal-domain>/api/v3/mcp`) and add it to your client as a custom MCP server.
1. After adding the MCP server, you need to authenticate. This typically opens your browser so you can log in to {{site.dev_portal}} and complete authorization, but the exact process varies across MCP clients.
1. If the agent needs to actually call the APIs it discovers, the developer must still separately generate the application's credentials and share them with the agent.

Once connected, a developer might prompt their agent with something like:

* "What APIs are published to this portal?"
* "Show me the documentation for the Payments API."
* "Create a real-time weather forecasting application from these APIs"
* "Register an application for the Payments API." (requires write operations to be enabled)
