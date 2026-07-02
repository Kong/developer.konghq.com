---
title: "Connect MCP clients to {{site.context_mesh}}"
description: "Configure MCP clients including Claude Code CLI, VS Code, Cursor, and GitHub Copilot to connect to your {{site.context_mesh}} servers."
content_type: reference
layout: reference
products:
  - konnect
  - ai-gateway
tags:
  - ai
  - mcp
works_on:
  - konnect
breadcrumbs:
  - /context-mesh/
permalink: /context-mesh/client-installation/

related_resources:
  - text: "Get started with {{site.context_mesh}}"
    url: /context-mesh/get-started/
  - text: "{{site.context_mesh}}"
    url: /context-mesh/
---

Once you've created a {{site.context_mesh}} MCP server, configure your MCP client by adding the server endpoint and any required authentication headers. Replace the placeholders below with your server's actual URL and credentials.

## Generic MCP client config

For any standard MCP client, use this JSON configuration format:

```json
{
  "mcpServers": {
    "SERVER_NAME": {
      "url": "http://localhost/mcp/SERVER_PATH",
      "headers": {
        "HEADER_NAME": "${ENV_VAR_NAME}"
      }
    }
  }
}
```

Replace:
- `SERVER_NAME` with your server's name (e.g., `flights_service`, `openweather-service`)
- `http://localhost/mcp/SERVER_PATH` with your server's endpoint URL
- `HEADER_NAME` and `ENV_VAR_NAME` with the authentication header required by your API

## {{ site.claude_code }} CLI

Using the `claude mcp add` command:

```bash
claude mcp add --transport http SERVER_NAME \
  http://localhost/mcp/SERVER_PATH \
  --header "HEADER_NAME: ${ENV_VAR_NAME}"
```

Or edit `~/.claude.json` directly:

```json
{
  "mcpServers": {
    "SERVER_NAME": {
      "url": "http://localhost/mcp/SERVER_PATH",
      "headers": {
        "HEADER_NAME": "${ENV_VAR_NAME}"
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

You should see your server listed with a status indicator.

## Visual Studio Code

1. Open Visual Studio Code
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
1. Type "MCP" and select **MCP: Open User Configuration**
1. Add your {{site.context_mesh}} server configuration:

    ```json
    {
      "inputs": [
        {
          "type": "promptString",
          "id": "api_key",
          "description": "API Key or Token",
          "password": true
        }
      ],
      "servers": {
        "SERVER_NAME": {
          "type": "http",
          "url": "http://localhost/mcp/SERVER_PATH",
          "headers": {
            "HEADER_NAME": "${input:api_key}"
          }
        }
      }
    }
    ```

1. Replace the placeholders with your server details
1. Save the configuration file
1. Reload VS Code (Command Palette > **Developer: Reload Window**)
1. When prompted, enter your API key or authentication token
1. Verify the server is running in the MCP settings

{:.info}
> VS Code securely stores your credentials after the first prompt.

## Cursor

1. Open the Cursor desktop app
1. Navigate to **Cursor Settings** (gear icon in top right corner)
1. Select **MCP** from the left sidebar
1. Click **+ Add new global MCP server**
1. Paste the following JSON configuration:

    ```json
    {
      "mcpServers": {
        "SERVER_NAME": {
          "url": "http://localhost/mcp/SERVER_PATH",
          "headers": {
            "HEADER_NAME": "${ENV_VAR_NAME}"
          }
        }
      }
    }
    ```

1. Replace the placeholders with your server details
1. Save the configuration file
1. Return to **Cursor Settings > MCP** and verify your server is listed
1. Press `Cmd+L` (Mac) or `Ctrl+L` (Windows/Linux) to open Cursor chat
1. Click `@` to add context and select tools from your {{site.context_mesh}} server

## GitHub Copilot for VS Code

1. Open Visual Studio Code
1. Ensure GitHub Copilot extension is installed
1. Open the Command Palette (`Cmd+Shift+P` on Mac, `Ctrl+Shift+P` on Windows/Linux)
1. Type "MCP" and select **MCP: Open User Configuration**
1. Add your {{site.context_mesh}} server configuration:

    ```json
    {
      "inputs": [
        {
          "type": "promptString",
          "id": "api_key",
          "description": "API Key or Token",
          "password": true
        }
      ],
      "servers": {
        "SERVER_NAME": {
          "type": "http",
          "url": "http://localhost/mcp/SERVER_PATH",
          "headers": {
            "HEADER_NAME": "${input:api_key}"
          }
        }
      }
    }
    ```

1. Replace the placeholders with your server details
1. Save the configuration file
1. Reload VS Code (Command Palette > **Developer: Reload Window**)
1. When prompted, enter your API key
1. Open GitHub Copilot chat and verify your {{site.context_mesh}} tools are available

{:.info}
> VS Code securely stores your credentials after the first prompt.

## GitHub Copilot for JetBrains

For IntelliJ IDEA, PyCharm, WebStorm, and other JetBrains IDEs:

1. Open your JetBrains IDE
1. Ensure GitHub Copilot plugin is installed (version 1.5.50 or later)
1. Click the **GitHub Copilot** icon in the toolbar
1. Select **Open Chat**
1. Switch to **Agent mode** in the chat panel
1. Click the **tools icon** (wrench/settings)
1. Select **Edit settings** to open MCP configuration
1. Add your {{site.context_mesh}} server configuration:

    ```json
    {
      "servers": {
        "SERVER_NAME": {
          "type": "http",
          "url": "http://localhost/mcp/SERVER_PATH",
          "headers": {
            "HEADER_NAME": "${ENV_VAR_NAME}"
          }
        }
      }
    }
    ```

1. Replace the placeholders with your server details
1. Save the configuration file
1. Restart your IDE
1. Open GitHub Copilot chat and verify your {{site.context_mesh}} tools are available

## Windsurf

1. Open Windsurf
1. Navigate to `~/.codeium/windsurf/`
1. Create or edit `mcp_config.json`:

    ```json
    {
      "mcpServers": {
        "SERVER_NAME": {
          "url": "http://localhost/mcp/SERVER_PATH",
          "headers": {
            "HEADER_NAME": "${ENV_VAR_NAME}"
          }
        }
      }
    }
    ```

1. Replace the placeholders with your server details
1. Save the file
1. Restart Windsurf
1. Open Cascade chat and verify your {{site.context_mesh}} tools are available

## Other IDEs

For Eclipse, Xcode, and other IDEs with MCP or GitHub Copilot support:

1. Locate your IDE's MCP or GitHub Copilot settings
1. Add your {{site.context_mesh}} server using the generic JSON format:

    ```json
    {
      "mcpServers": {
        "SERVER_NAME": {
          "url": "http://localhost/mcp/SERVER_PATH",
          "headers": {
            "HEADER_NAME": "${ENV_VAR_NAME}"
          }
        }
      }
    }
    ```

1. Replace the placeholders with your server details
1. Save and restart your IDE
1. Verify your {{site.context_mesh}} tools are available in your AI assistant

{:.info}
> Configuration methods vary by IDE. Consult your IDE's documentation for MCP server setup instructions.

## Common headers

Different APIs require different authentication headers. Check your API's requirements:

| API | Header | Example |
|-----|--------|---------|
| Flights (KongAir) | `X-Upstream-Bearer-Token` | JWT token from KongAir |
| OpenWeather | `X-Upstream-Api-Key` | API key from OpenWeatherMap |
| Custom API | Depends on API | Consult API documentation |

Export your credentials as environment variables before using the CLI or configuration files:

```bash
export FLIGHTS_TOKEN=<your-token>
export OPENWEATHERMAP_API_KEY=<your-api-key>
```
