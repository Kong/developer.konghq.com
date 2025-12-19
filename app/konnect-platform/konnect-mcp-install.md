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

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

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

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

1. Open Visual Studio Code
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
1. Type "MCP" and select **MCP: Open User Configuration**
1. Add the {{site.konnect_product_name}} server configuration:

    ```json
    {
      "inputs": [
        {
          "type": "promptString",
          "id": "konnect_mcp_pat",
          "description": "Konnect Personal Access Token",
          "password": true
        }
      ],
      "servers": {
        "kong-konnect": {
          "type": "http",
          "url": "https://us.mcp.konghq.com/",
          "headers": {
            "Authorization": "Bearer ${input:konnect_mcp_pat}"
          }
        }
      }
    }
    ```

1. Replace `https://us.mcp.konghq.com/` with your regional server URL if needed
1. Save the configuration file
1. Reload VS Code window (Command Palette > **Developer: Reload Window**)
1. When prompted, enter your {{site.konnect_product_name}} Personal Access Token or System Access Token
1. Press Enter to confirm
1. In the `mcp.json` settings file you should see that the server is running and that the tools are available

{:.info}
> VS Code securely stores your PAT after the first prompt. The value is not visible in the configuration file.

## Cursor

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

1. Open the Cursor desktop app
1. Navigate to **Cursor Settings** (gear icon in top right corner)
1. Select **MCP** from the left sidebar
1. Click **+ Add new global MCP server**
1. Paste the following JSON configuration into the `mcp.json` file:

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
1. Return to **Cursor Settings > MCP**. You should now see the `kong-konnect` MCP server with available tools listed
1. To open a new Cursor chat, press `Cmd+L` (Mac) or `Ctrl+L` (Windows/Linux)
1. In the Cursor chat, click `@` to add context and select tools from the Kong {{site.konnect_product_name}} server

## GitHub Copilot for VS Code

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

1. Open Visual Studio Code
1. Ensure GitHub Copilot extension is installed and configured
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
1. Type "MCP" and select **MCP: Open User Configuration**
1. Add the {{site.konnect_product_name}} server configuration:

    ```json
    {
      "inputs": [
        {
          "type": "promptString",
          "id": "konnect_mcp_pat",
          "description": "Konnect Personal Access Token",
          "password": true
        }
      ],
      "servers": {
        "kong-konnect": {
          "type": "http",
          "url": "https://us.mcp.konghq.com/",
          "headers": {
            "Authorization": "Bearer ${input:konnect_mcp_pat}"
          }
        }
      }
    }
    ```

1. Replace `https://us.mcp.konghq.com/` with your regional server URL if needed
1. Save the configuration file
1. Reload VS Code window (Command Palette > **Developer: Reload Window**)
1. When prompted, enter your {{site.konnect_product_name}} Personal Access Token
1. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

{:.info}
> VS Code securely stores your PAT after the first prompt. The value is not visible in the configuration file.

## GitHub Copilot for JetBrains

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

For IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains IDEs:

1. Open your JetBrains IDE
1. Ensure GitHub Copilot plugin is installed and configured (version 1.5.50 or later)
1. Click the **GitHub Copilot** icon in the toolbar
1. Select **Open Chat**
1. Switch to **Agent mode** in the chat panel
1. Click the **tools icon** (wrench/settings)
1. Select **Edit settings** to open the MCP configuration
1. Add the {{site.konnect_product_name}} server configuration:

    ```json
    {
      "servers": {
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

1. Replace `https://us.mcp.konghq.com/` with your regional server URL
1. Replace `YOUR_KONNECT_PAT` with your actual Personal Access Token
1. Save the configuration file
1. Restart your IDE
1. Open GitHub Copilot chat and verify Kong {{site.konnect_product_name}} tools are available

## Windsurf

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

1. Open Windsurf
1. Navigate to the configuration directory: `~/.codeium/windsurf/`
1. Create or edit the file `mcp_config.json`:

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
1. Save the file
1. Restart Windsurf
1. Open Cascade chat and verify Kong {{site.konnect_product_name}} tools are available

## Other IDEs

For regional server URLs, see [Regional server endpoints](/konnect-platform/konnect-mcp/#regional-server-endpoints).

For Eclipse, Xcode, and other IDEs with GitHub Copilot support:

1. Install the GitHub Copilot extension/plugin for your IDE
1. Open the GitHub Copilot preferences or settings
1. Navigate to the MCP configuration section
1. Add the {{site.konnect_product_name}} MCP server configuration:

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
1. Save the configuration
1. Restart your IDE
1. Open the AI assistant and verify Kong {{site.konnect_product_name}} tools are available

{:.info}
> Configuration methods vary by IDE. Consult your IDE's GitHub Copilot or MCP documentation for specific setup instructions.