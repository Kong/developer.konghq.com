---
title: "{{site.ai_gateway}} on-prem UI (Kong AI Manager)"

description: "Use Kong AI Manager, a local file-based UI, to import, create, edit, and export {{site.ai_gateway}} 2.x decK and {{site.operator_product_name}} configuration for on-prem deployments."

content_type: reference
layout: reference

products:
  - ai-gateway

works_on:
  - on-prem

min_version:
  ai-gateway: '2.4'

tags:
  - ai

breadcrumbs:
  - /ai-gateway/

related_resources:
  - text: "Configure {{site.ai_gateway_name}} on-prem"
    url: /ai-gateway/configure-on-prem/
  - text: "Migrate to {{site.ai_gateway}} 2.x on-prem"
    url: /ai-gateway/on-prem-migration/
  - text: "Install {{site.ai_gateway}} 2.x on-prem using Docker Compose"
    url: /ai-gateway/install/docker/
  - text: "Install {{site.ai_gateway_name}} on-prem with {{site.operator_product_name}} (Tech Preview)"
    url: /operator/get-started/ai-gateway/install/
  - text: "{{site.ai_gateway}} entities"
    url: /ai-gateway/entities/
  - text: deck ai sync
    url: /deck/ai/sync/
  - text: deck file ai2kong
    url: /deck/file/ai2kong/
---

Kong AI Manager is a local, file-based UI for building and editing {{site.ai_gateway}} 2.x configuration for on-prem deployments.
On-prem {{site.ai_gateway}} Enterprise users manage AI Models, AI MCP Servers, and AI Agents by writing decK or {{site.operator_product_name}} YAML by hand.
Kong AI Manager lets you build and edit that configuration in forms instead, and it writes the result back to files in the same format.

Kong AI Manager runs on your machine, in your browser.
It doesn't connect to a cluster, to {{site.konnect_short_name}}, or to the internet.

{:.warning}
> Kong AI Manager **doesn't apply configuration changes**. It only reads and writes files. After you export your configuration, apply it yourself with [`deck ai sync`](/deck/ai/sync/) or `kubectl apply`.

## Prerequisites

* Node.js 22.19.0 or later.

{:.info}
> **Configuration file (optional)**
> <br>
> You don't need an existing configuration to use Kong AI Manager. You can create a new project from scratch, or load the built-in example to explore the UI.
> <br><br>
> To edit an existing configuration, have one of the following ready as a `.yaml`, `.yml`, or `.json` file:
> * A decK configuration file for {{site.ai_gateway}} 2.x. See [Interacting with {{site.ai_gateway}} entities](/deck/ai/) and [Configure {{site.ai_gateway_name}} on-prem](/ai-gateway/configure-on-prem/).
> * {{site.operator_product_name}} manifests (Tech Preview). See [{{site.ai_gateway_name}} with {{site.operator_product_name}}](/operator/ai-gateway/) and [Install {{site.ai_gateway_name}} on-prem with {{site.operator_product_name}}](/operator/get-started/ai-gateway/install/).
>
> A project holds one format. See [Project formats](#project-formats) for how the format affects import and export.

## Run Kong AI Manager

From the terminal, run:

```sh
npx @kong/ai-manager
```

The command starts a server on `http://127.0.0.1:3000`, prints the address with an access token, and opens your browser.
The token in the URL is a bearer credential, so don't share the URL.
The server listens on the loopback address only.

To open a specific folder, use the `--dir` option:

```sh
npx @kong/ai-manager --dir ./kong-config
```

The following table lists the command options:

{% table %}
columns:
  - title: Option
    key: option
  - title: Description
    key: description
rows:
  - option: "`-p, --port <number>`"
    description: "Port to listen on. Default: `3000`. If the port is busy, Kong AI Manager uses the next free port."
  - option: "`-d, --dir <path>`"
    description: "Folder to open first. Default: the current directory."
  - option: "`--no-open`"
    description: "Don't open the browser."
  - option: "`--upstream-versions`"
    description: "Print the upstream versions this build supports, and exit."
  - option: "`-h, --help`"
    description: "Show the command help."
{% endtable %}

If the folder contains a file that Kong AI Manager can edit, it opens that folder as a project.
Otherwise, it shows the **Open project** page, where you can pick a recent project, browse folders, or create a new project.

## Project formats

A project holds one format. The format decides which files you can import and which files the export writes.

{% table %}
columns:
  - title: Format
    key: format
  - title: Use it for
    key: use
  - title: Apply the exported config with
    key: apply
rows:
  - format: "decK configuration"
    use: "On-prem {{site.ai_gateway}} that runs on self-managed {{site.base_gateway}} without {{site.operator_product_name}}."
    apply: "[`deck ai sync`](/deck/ai/sync/) or [`deck file ai2kong`](/deck/file/ai2kong/)"
  - format: "{{site.operator_product_name}} manifests (Tech Preview)"
    use: "{{site.ai_gateway}} on Kubernetes with {{site.operator_product_name}}."
    apply: "`kubectl apply`"
{% endtable %}

The format is set when you import or create the first file, and it stays until you remove every file from the project.
A decK project doesn't show pages for resources that the decK format can't carry, such as AI Gateways, data planes, and Secrets.

## Import configuration

Every page reads all files in the project together, so a resource in one file can reference a resource in another file.

To import your own configuration:

1. In the sidebar, click **Overview**.
1. In the **Files** panel, click **Import**.
1. Click **Import files** to select `.yaml`, `.yml`, or `.json` files, or click **Import folder** to import every YAML and JSON file in a folder. Folder import keeps each file's path.
1. If the project is empty, choose the project format, for example **decK configuration**, and click **Continue**.

To explore the UI before importing your own files, click **Import** in the **Files** panel, then click **Load example**. This adds a demo configuration for a fictional airline.

If you import a file in the other format into a project that already has files, Kong AI Manager skips the file and shows a warning.

## Create and edit resources

Each resource opens as a form. Reference fields list the matching resources from the whole project, and the **File** field sets which file in the project holds the resource.

Use the following pages to manage the main {{site.ai_gateway}} resources:

* **Models**: [AI Models](/ai-gateway/entities/ai-model/), including their target providers, routes, access control, and policies.
* **MCP servers**: [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/).
* **Agents**: [AI Agents](/ai-gateway/entities/ai-agent/).

The sidebar also has pages for providers, datastores, CA certificates, certificates, vaults, policies, auth strategies, and consumers.

### Create an AI Model

1. In the sidebar, click **Models**.
1. Click **New**, then click **Model**.
1. Complete the form, and in the **File** field, select the file that holds the AI Model.
1. Click **Create**.

### Create an AI MCP Server

1. In the sidebar, click **MCP servers**.
1. Click **New**, then click **MCP server**.
1. In the **Name** field, enter a name for the AI MCP Server.
1. In the **Connection** section, select **Passthrough**, **Interface**, or **From API**.
1. In the **File** field, select the file that holds the AI MCP Server.
1. Complete the **Configuration** section.
1. Click **Create**.

### Create an AI Agent

1. In the sidebar, click **Agents**.
1. Click **New agent**.
1. In the **Name** field, enter a name for the AI Agent.
1. In the **Type** field, select the agent type, for example **A2A (Agent-to-Agent)**.
1. In the **File** field, select the file that holds the AI Agent.
1. Complete the **Configuration** section.
1. Click **Create**.

### Edit a resource

1. In the sidebar, click the resource type, for example **Models**.
1. Click the resource name in the list.
1. Change the fields.
<!-- TODO: confirm the exact label of the save button on an edit form -->
1. Save the change.

How a save works depends on the project type:

* **Folder project**: saving writes the change to the file on disk immediately. Edits you make to the files outside the UI also appear in the UI.
* **Scratch project** (no folder access): saving changes the project in memory only. Reloading or closing the tab loses the project, so export it first.

## Export configuration

The export uses the same format as the project, so decK input produces decK output and {{site.operator_product_name}} input produces {{site.operator_product_name}} manifests.

To export configuration:

1. In the sidebar, click **Overview**.
1. To export one file, click the file in the **Files** panel, click **Actions**, and click **Export**.
1. To export the whole project, in the **Files** panel, click **Export all**.

Before the download, the export shows the exact file content and a sample command to apply it:

* For decK projects, Kong AI Manager shows `deck ai sync` or `deck file ai2kong`. **Export all** produces a single file, because `deck ai sync` reads each file on its own and can't resolve references between files.
* For {{site.operator_product_name}} projects, Kong AI Manager shows `kubectl apply`. **Export all** downloads a zip archive that keeps every file at its path.

For decK projects, Kong AI Manager validates each entity against the {{site.ai_gateway}} API request schema and shows mismatches as warnings. Warnings never block an export.

{:.danger}
> Exported files can contain secret values in plain text. Don't commit an exported file that contains secrets to version control. Use [AI Vault](/ai-gateway/entities/ai-vault/) references where possible.

## Apply the exported configuration

Kong AI Manager doesn't connect to your gateway, so apply the exported file yourself:

* **decK**: run [`deck ai sync`](/deck/ai/sync/) against your on-prem {{site.ai_gateway}} deployment.
* **{{site.operator_product_name}}**: run `kubectl apply` against the cluster that runs {{site.operator_product_name}}.

## Supported versions

Each Kong AI Manager release supports specific versions of {{site.ai_gateway}}, decK, and {{site.operator_product_name}}.
To see them, click the info icon in the header, or run:

```sh
npx @kong/ai-manager --upstream-versions
```
