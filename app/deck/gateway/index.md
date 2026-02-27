---
title: deck gateway
description: Manage {{ site.base_gateway }} declaratively

content_type: reference
layout: reference

works_on:
  - on-prem
  - konnect

tools:
  - deck

breadcrumbs:
  - /deck/

tags:
  - declarative-config

related_resources:
  - text: decK file management commands
    url: /deck/file/
---

decK can configure a running {{ site.base_gateway }} using the `deck gateway` command.

decK interacts with {{ site.base_gateway }} using the Kong Admin API.
This means that decK can manage any {{ site.base_gateway }} instance running in hybrid or traditional mode, or in any {{site.konnect_short_name}} deployment. However, it can't manage Gateways running in DB-less mode.

To learn about decK's APIOps capabilities, see [deck file](/deck/file).

decK provides the following `deck gateway` subcommands:

<!--vale off-->
{% table %}
columns:
  - title: Command
    key: command
  - title: Description
    key: description
rows:
  - command: "[ping](/deck/gateway/ping/)"
    description: Verify that decK can talk to the configured Admin API.
  - command: "[validate](/deck/gateway/validate/)"
    description: Validate the data in the provided state file against a live Admin API.
  - command: "[diff](/deck/gateway/diff/)"
    description: "Diff the current state of {{ site.base_gateway }} against the provided configuration."
  - command: "[sync](/deck/gateway/sync/)"
    description: "Update {{ site.base_gateway }} to match the state defined in the provided configuration."
  - command: "[apply](/deck/gateway/apply/)"
    description: Apply configuration to Kong without deleting existing entities.
  - command: "[dump](/deck/gateway/dump/)"
    description: "Export the current state of {{ site.base_gateway }} to a file."
  - command: "[reset](/deck/gateway/reset/)"
    description: "Delete all entities in {{ site.base_gateway }}."
{% endtable %}
<!--vale on-->

All of these commands require access to a running {{ site.base_gateway }} to function. If your Admin API requires a token, see the [configuration](/deck/gateway/configuration/) page.
