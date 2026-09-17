---
title: "{{site.context_mesh}} MCP servers"
content_type: reference
layout: reference

description: "Reference for {{site.context_mesh}} MCP servers, including how REST APIs are exposed as Code Mode MCP servers and how those servers are deployed and configured."

products:
    - context-mesh
    - konnect

works_on:
    - konnect

breadcrumbs:
  - /context-mesh/

tags:
  - mcp
  - ai

search_aliases:
  - Code Mode MCP
  - MCP server

---

{{site.context_mesh}} lets you turn enterprise assets (such as MCP servers and APIs) into context that AI agents can call. It works by composing those assets into a single deployable Code Mode MCP server, also called a Context Interface.

## Sources

Sources are the individual assets you add to {{site.context_mesh}} to compose create a deployable  MCP server. There are two types of sources:

- APIs: Hosted on {{site.konnect}}, or externally hosted.
- MCP servers endpoints

To create a MCP server, you need to add sources to {{site.context_mesh}}. Once you've added sources, you can combine and reuse them to create different contexts. A source carries the following fields:

{% feature_table %}
item_title: Field
columns:
  - title: Description
    key: description
  - title: Can be edited
    key: edit

features:
  - title: "Type"
    description: Specifies the access and resources that are granted.
    global_scope: false
  - title: "Metadata"
    description: |
      Assigns a set of `AccessRoles` to a set of objects (users and groups).
    global_scope: true
  - title: "Definition"
    description: .
    global_scope: true

{% endfeature_table %}

## Context Interfaces

## Auth

## Deployments