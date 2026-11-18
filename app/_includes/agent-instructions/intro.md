## Instructions for AI agents

This page is written for a person. If you have the {{site.konnect_product_name}} MCP server connected, use its tools instead of the literal commands the guide shows.

### Discover the tools first

The MCP server exposes a small set of tools that work together. Find the operation you need, read its schema, then call it. Do not call a tool name or a path from memory.

### Use {{site.code_mode}} where available

Where the client supports {{site.code_mode}}, keep the task inside one session. Several related calls in one session cost less than one tool call per step.

### Read before you write

List or get the current state of every entity you are about to change. Create only what is missing, and update in place. Do not assume an entity exists because the guide mentions it.

### Take IDs from tool responses

Read the ID of every entity you create from the tool response. Do not reuse an ID from an example on the page, and do not build an ID from a name.
