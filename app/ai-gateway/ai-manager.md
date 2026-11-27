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
On-prem {{site.ai_gateway}} Enterprise users manage AI Models, AI MCP Servers, and AI Agents by writing [decK](/deck/) or [{{site.operator_product_name}}](/operator/) YAML manually.
Kong AI Manager lets you build and edit that configuration in forms instead, and it writes the result back to files in the same format.

Kong AI Manager runs on your machine, in your browser.
It doesn't connect to a cluster, to {{site.konnect_short_name}}, or to the internet.

{:.warning}
> Kong AI Manager **does not apply configuration changes**. It only reads and writes files. After you export your configuration, apply it yourself with [`deck ai sync`](/deck/ai/sync/) or `kubectl apply`.

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

Start Kong AI Manager with `npx`:

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
Otherwise, it shows the **Open project** page.

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
    apply: "[`deck ai sync`](/deck/ai/sync/)"
  - format: "{{site.operator_product_name}} manifests (Tech Preview)"
    use: "{{site.ai_gateway}} on Kubernetes with {{site.operator_product_name}}."
    apply: "`kubectl apply`"
{% endtable %}

The format is set when you import or create the first file, and it stays until you remove every file from the project.
A decK project doesn't show pages for resources that the decK format can't carry, such as AI Gateways, data planes, and Secrets.

## Import configuration

Kong AI Manager reads all files in a project together, so a resource in one file can reference a resource in another file.

Import files from the **Files** panel on the **Overview** page.
You can import individual `.yaml`, `.yml`, or `.json` files, or import a folder, which imports every YAML and JSON file in it and keeps each file's path.
When the project is empty, Kong AI Manager asks you to choose the project format, for example **decK configuration**.

To explore the UI before importing your own files, choose **Import** in the **Files** panel, then **Load example**.
It adds a demo configuration for a fictional airline.

If you import a file in the other format into a project that already has files, Kong AI Manager skips the file and shows a warning.

## Create and edit resources

Kong AI Manager opens each resource as a form.
Reference fields list the matching resources from the whole project, and the **File** field sets which file in the project holds the resource.

Use the following pages to manage the main {{site.ai_gateway}} resources:

* **Models**: [AI Models](/ai-gateway/entities/ai-model/), including their target providers, routes, access control, and policies.
* **MCP servers**: [AI MCP Servers](/ai-gateway/entities/ai-mcp-server/). Each server connects in one of three modes: **Passthrough**, **Interface**, or **From API**.
* **Agents**: [AI Agents](/ai-gateway/entities/ai-agent/). Each agent has a type, for example **A2A (Agent-to-Agent)**.

How a save works depends on the project type:

* **Folder project**: saving writes the change to the file on disk immediately. Edits you make to the files outside the UI also appear in the UI.
* **Scratch project** (no folder access): saving changes the project in memory only. Reloading or closing the tab loses the project, so export it first.

Use a folder project for configuration that you keep in files, such as a repository, because saves go straight to disk.
Use a scratch project to try the UI or make a one-off edit, because nothing is written until you export.

## Export configuration

Kong AI Manager exports in the same format as the project, so decK input produces decK output and {{site.operator_product_name}} input produces {{site.operator_product_name}} manifests.

Export from the **Files** panel on the **Overview** page.
You can export one file, or choose **Export all** to export the whole project.

Before the download, the export shows the exact file content and a sample command to apply it:

* For decK projects, Kong AI Manager shows `deck ai sync` or `deck file ai2kong`. **Export all** produces a single file.
* For {{site.operator_product_name}} projects, Kong AI Manager shows `kubectl apply`. **Export all** downloads a zip archive that keeps every file at its path.

For decK projects, Kong AI Manager validates each entity against the {{site.ai_gateway}} API request schema and shows mismatches as warnings. Warnings never block an export.

{:.danger}
> Exported files can contain secret values in plain text. **Do not** commit an exported file that contains secrets to version control. Use [AI Vault](/ai-gateway/entities/ai-vault/) references where possible.

## Apply the exported configuration

Apply the exported file with the command for your project format:

* **decK**: run [`deck ai sync`](/deck/ai/sync/) against your on-prem {{site.ai_gateway}} deployment.
* **{{site.operator_product_name}}**: run `kubectl apply` against the cluster that runs {{site.operator_product_name}}.

## Supported versions

Each Kong AI Manager release supports specific versions of {{site.ai_gateway}}, decK, and {{site.operator_product_name}}.
To see them, click the info icon in the header, or run:

```sh
npx @kong/ai-manager --upstream-versions
```
