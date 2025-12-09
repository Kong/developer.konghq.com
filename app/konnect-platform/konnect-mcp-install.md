---
title: "Install {{site.konnect_product_name}} MCP Server"
description: "Configure the {{site.konnect_product_name}} MCP Server with AI assistants and IDE copilots including Claude Code CLI, VS Code, Cursor, and GitHub Copilot."
content_type: reference
layout: reference
products:
  - konnect
tags:
  - ai
  - mcp
works_on:
  - konnect
breadcrumbs:
  - /konnect/
  - /konnect-platform/kai/
  - /konnect-platform/konnect-mcp/
permalink: /konnect-platform/konnect-mcp/installation/

beta: true

related_resources:
  - text: "{{site.konnect_product_name}} MCP Server"
    url: /konnect-platform/konnect-mcp/
  - text: "About Kong's AI assistant"
    url: /konnect-platform/kai/
---

Configure the MCP client of your choice by adding the {{site.konnect_product_name}} MCP Server with your regional URL and PAT.

## Claude Code CLI

**Using the `claude mcp add` command:**

```bash
claude mcp add --transport http kong-konnect https://us.mcp.konghq.com/ \
  --header "Authorization: Bearer YOUR_KONNECT_PAT"
```

{:.info}
> Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual Personal Access Token.

**You can also configure by editing the configuration file directly:**

Claude CLI stores its configuration in `~/.claude.json` (or `.mcp.json` for project scope):

```json
{
  "mcpServers": {
    "kong-konnect": {
      "type": "http",
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

**Verify the configuration**

List all configured servers:

```bash
claude mcp list
```

Get details for the Kong {{site.konnect_product_name}} server:

```bash
claude mcp get kong-konnect
```

## Visual Studio Code

1. Open Visual Studio Code
2. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
3. Type "MCP" and select "MCP: Configure Servers"
4. Add the Kong {{site.konnect_product_name}} server configuration:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

5. Replace `https://us.mcp.konghq.com/` with your regional server URL
6. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
7. Save the configuration file
8. Reload VS Code window (Command Palette > "Developer: Reload Window")
9. Open the AI assistant and verify Kong {{site.konnect_product_name}} tools are available

## Cursor

1. Open your Cursor desktop app
2. Navigate to Settings in the top right corner (gear icon)
3. In the Cursor Settings tab, go to Tools & MCP in the left sidebar
4. In the Installed MCP Servers section, click "New MCP Server"
5. Paste the following JSON configuration into the newly opened `mcp.json` tab:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

6. Replace `https://us.mcp.konghq.com/` with your regional server URL
7. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
8. Save the configuration file
9. Return to the Cursor settings tab. You should now see the `kong-konnect` MCP server with available tools listed
10. To open a new Cursor chat, press `Cmd+L` (Mac) or `Ctrl+L` (Windows/Linux)
11. In the Cursor chat tab, click `@` Add Context and select tools from the Kong {{site.konnect_product_name}} server

## GitHub Copilot for VS Code

1. Open Visual Studio Code
2. Ensure GitHub Copilot extension is installed and configured
3. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
4. Type "MCP" and select "MCP: Configure Servers"
5. Add the Kong {{site.konnect_product_name}} server configuration:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

6. Replace `https://us.mcp.konghq.com/` with your regional server URL
7. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
8. Save the configuration file
9. Reload VS Code window (Command Palette > "Developer: Reload Window")
10. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

## GitHub Copilot for JetBrains

**For IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains IDEs:**

1. Open your JetBrains IDE
2. Navigate to Settings/Preferences (`Cmd+,` on Mac, `Ctrl+Alt+S` on Windows/Linux)
3. Go to Tools > GitHub Copilot > MCP Servers
4. Click the "+" button to add a new server
5. Enter the server details:
   - **Name**: Kong {{site.konnect_product_name}}
   - **URL**: `https://us.mcp.konghq.com/` (or your regional URL)
   - **Transport**: SSE
   - **Authentication**: Bearer Token
   - **Token**: Your {{site.konnect_product_name}} PAT
6. Click "OK" to save
7. Restart your IDE
8. Invoke GitHub Copilot and verify Kong {{site.konnect_product_name}} tools are available

**Manual Configuration:**

If your JetBrains IDE doesn't provide the UI option, edit the configuration file at:
`~/.config/JetBrains/<IDE>/mcp-servers.json`

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual token, then restart your IDE.

## Other IDEs

**For Visual Studio:**

1. Open Visual Studio
2. Navigate to Tools > Options
3. Expand GitHub > Copilot
4. Select "MCP Servers"
5. Click "Add"
6. Configure the server:
   - **Name**: Kong {{site.konnect_product_name}}
   - **Server URL**: `https://us.mcp.konghq.com/` (or your regional URL)
   - **Transport Type**: Server-Sent Events
   - **Authentication**: Bearer Token
   - **Token**: Your {{site.konnect_product_name}} PAT
7. Click "OK" to save
8. Restart Visual Studio
9. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

**Configuration File Location:**
`%LOCALAPPDATA%\Microsoft\VisualStudio\<Version>\Extensions\mcp-config.json`

**For Eclipse and Other IDEs:**

If your IDE doesn't provide a UI for MCP configuration, manually edit the configuration file:

```json
{
  "mcpServers": {
    "kong-konnect": {
      "url": "https://us.mcp.konghq.com/",
      "headers": {
        "Authorization": "Bearer YOUR_KONNECT_PAT"
      }
    }
  }
}
```

**Configuration file locations:**
- **Eclipse**: `.metadata/.plugins/org.eclipse.core.runtime/.settings/com.github.copilot.prefs`
- **Other IDEs**: Consult your IDE's GitHub Copilot documentation for the MCP configuration file location

Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual token, then restart your IDE.