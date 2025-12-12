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

Using the `claude mcp add` command:

```bash
claude mcp add --transport http kong-konnect https://us.mcp.konghq.com/ \
  --header "Authorization: Bearer YOUR_KONNECT_PAT"
```

{:.info}
> Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual Personal Access Token.

You can also configure by editing the configuration file directly:

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

```sh
claude mcp list
```

You should see the following output:

```sh
kong-konnect: https://us.mcp.konghq.com/ (HTTP) - ✓ Connected
```

## Visual Studio Code

1. Open Visual Studio Code
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
1. Type "MCP" and select "MCP: Open user configuration"
1. Add the {{site.konnect_product_name}} server configuration:

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

1. Replace `https://us.mcp.konghq.com/` with your regional server URL
1. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
1. Save the configuration file
1. Reload VS Code window (Command Palette > "Developer: Reload Window")
1. Open the AI assistant and verify Kong {{site.konnect_product_name}} tools are available

## Cursor

1. Open your Cursor desktop app
1. Navigate to **Settings** in the top right corner (gear icon)
1. In the Cursor **Settings** tab, go to **Tools & MCP** in the left sidebar
1. In the Installed MCP Servers section, click "New MCP Server"
1. Paste the following JSON configuration into the newly opened `mcp.json` tab:

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

1. Replace `https://us.mcp.konghq.com/` with your regional server URL
1. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
1. Save the configuration file
1. Return to **Cursor settings > Tools & MCP**. You should now see the `kong-konnect` MCP server with available tools listed
1. To open a new Cursor chat, press `Cmd+L` (Mac) or `Ctrl+L` (Windows/Linux)
1. In the Cursor chat tab, click `@` Add Context and select tools from the Kong {{site.konnect_product_name}} server

## GitHub Copilot for VS Code

1. Open Visual Studio Code
1. Ensure GitHub Copilot extension is installed and configured
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
1. Type "MCP" and select "MCP: Configure Servers"
1. Add the {{site.konnect_product_name}} server configuration:

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

1. Replace `https://us.mcp.konghq.com/` with your regional server URL
1. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
1. Save the configuration file
1. Reload VS Code window (Command Palette > "Developer: Reload Window")
1. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

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

{:.info}
> Replace `https://us.mcp.konghq.com/` with your regional server URL and `YOUR_KONNECT_PAT` with your actual token, then restart your IDE.

## Other IDEs

For IDEs without native MCP UI support (Windsurf, Eclipse, Xcode, and others), manually edit the MCP configuration file:
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

**Common configuration file locations:**
- **Windsurf**: `~/.windsurf/mcp-config.json`
- **Eclipse**: `.metadata/.plugins/org.eclipse.core.runtime/.settings/com.github.copilot.prefs`
- **Xcode**: `~/Library/Application Support/Xcode/mcp-config.json`
- **Other IDEs**: Consult your IDE's MCP or AI assistant documentation for the configuration file location