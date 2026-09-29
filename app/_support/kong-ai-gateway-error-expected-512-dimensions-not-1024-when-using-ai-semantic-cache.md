---
title: "{{site.ai_gateway_name}}: \"ERROR: expected 512 dimensions, not 1024\" when using `ai-semantic-cache`"
content_type: support
description: Switching embedding models to a different dimension size after the `ai-semantic-cache` plugin's vector table was created causes a Postgres dimension-mismatch error in the background cache-store logs.
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources: []
tldr:
  q: "Why does {{site.ai_gateway_name}} log \"ERROR: expected 512 dimensions, not 1024\" when using `ai-semantic-cache`?"
  a: |
    The `ai-semantic-cache` plugin's vector table locks in the embedding dimension size the first time it's used; switching to a model with a different dimension count doesn't update the table, so `config.vectordb.dimensions` no longer matches. Delete and re-create the plugin to regenerate the table with the new dimensions.
---

## Problem

The following error appears in the Gateway logs when using the `ai-semantic-cache` plugin:

`"Unable to store response in the cache: failed to insert key: ERROR: expected 512 dimensions, not 1024, context: ngx.timer"`

## Solution

This error occurs when the plugin was initially configured with a specific embedding dimension (e.g., 512), and later switched to an embedding model with a different dimension size (e.g., 1024). The underlying issue is that the embedding field in the vector database table is initialized using the dimensions set during the first use of the cache. Changing the model does not automatically update the table structure.

Note that if `config.vectordb.dimensions` isn't updated alongside the new model, Kong now intercepts the mismatch earlier and returns a synchronous 500 error to the client, rather than letting the request through. The `ERROR: expected 512 dimensions, not 1024` Postgres error above only ever appears in the Gateway's server logs — it comes from a background timer write (the cache-store step) and is never returned to the client.

To resolve this, you need to delete and re-create the plugin. Doing so generates a new table in the vector database with the correct embedding dimensions.
