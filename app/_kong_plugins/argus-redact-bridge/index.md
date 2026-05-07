---
title: 'Argus Redact Bridge'
name: 'Argus Redact Bridge'

content_type: plugin

publisher: wan9yu
description: 'Redact PII before upstream LLM calls, restore the original PII on the response, transparently.'

categories:
  - ai
  - transformations

products:
    - gateway
    - ai-gateway

works_on:
    - on-prem

third_party: true

support_url: https://github.com/wan9yu/kong-plugin-argus-redact/issues
source_code_url: https://github.com/wan9yu/kong-plugin-argus-redact
license_url: https://github.com/wan9yu/kong-plugin-argus-redact/blob/main/LICENSE

icon: argus-redact-bridge.svg

search_aliases:
  - argus
  - argus-redact
  - pii-redact
  - pii-pseudonym
  - reversible-redact

tags:
  - ai
  - security
  - dlp
  - privacy

min_version:
  gateway: '3.0'
---

The Argus Redact Bridge plugin replaces personally identifiable information (PII) in OpenAI-compatible Chat Completions requests with realistic pseudonyms before the request reaches the upstream LLM, then restores the original PII in the response on its way back to the client. The upstream model never sees raw PII; the human caller never has to decode pseudonyms.

The plugin pairs with [argus-redact](https://github.com/wan9yu/argus-redact) — an Apache-2.0 PII detection engine with strong Chinese-language coverage (HanLP names, GB MOD11-2 ID validation, PRC mobile / landline / bank-card patterns) plus seven additional language packs (en, ja, ko, de, uk, in, br).

## How it works

1. **Access phase** — the plugin extracts each `messages[].content` from the request body, posts it to the argus-redact sidecar's `/redact` endpoint, replaces the content with the pseudonymized form (default profile: `pseudonym-llm`, which emits realistic-looking but reserved-range fake values), and stashes the merged `{placeholder → original}` key map in the request context.
2. **Body filter phase** — the plugin buffers the upstream response until EOF, parses each `choices[].message.content`, and restores the original PII via local string substitution against the stashed key map.

{% mermaid %}
sequenceDiagram
    autonumber
    participant Client
    participant Kong as Kong + Argus Redact Bridge
    participant Argus as argus-redact sidecar
    participant LLM as Upstream LLM

    Client->>Kong: POST /v1/chat/completions (real PII)
    Kong->>Argus: POST /redact (per messages[i])
    Argus-->>Kong: {redacted, key}
    Note over Kong: stash merged key
    Kong->>LLM: forward (pseudonymized body)
    LLM-->>Kong: response (still pseudonymized)
    Note over Kong: body_filter — local restore via key dict
    Kong-->>Client: response (real PII restored)
{% endmermaid %}

**Failure mode.** When `on_error: closed` (default) and the argus-redact sidecar is unreachable during the access phase, the request is rejected with HTTP 503 — unredacted PII never reaches the upstream LLM. Set `on_error: open` to fail-open with a warning log instead.

## Why use this plugin

This is a community-maintained Apache-2.0 plugin that complements existing {{site.ai_gateway}} options for teams that:

* run {{site.base_gateway}} OSS and need a reversible (round-trip) PII handling pattern
* primarily process Chinese-language traffic and want native validators rather than regex-only matching
* prefer a fully open-source PII engine they can audit, modify, and self-host without vendor coordination

For traffic that is non-Chinese-heavy, that requires enterprise tier features, or where reversibility is not required, the existing AI Gateway guardrail and content-safety plugins remain the right choice.

## Install the Argus Redact Bridge plugin

1. Install the Lua plugin via LuaRocks:

   ```sh
   luarocks install argus-redact-bridge
   ```

2. Register the plugin in `kong.conf` (or via the `KONG_PLUGINS` environment variable):

   ```
   plugins = bundled,argus-redact-bridge
   ```

3. Run an [argus-redact](https://github.com/wan9yu/argus-redact) sidecar reachable from {{site.base_gateway}}:

   ```sh
   pip install 'argus-redact[serve]'
   export ARGUS_API_KEY=<your-bearer-token>
   argus-redact serve --host 0.0.0.0 --port 8000
   ```

4. Restart {{site.base_gateway}}:

   ```sh
   kong restart
   ```

A self-contained docker-compose stack (Kong + sidecar + mock LLM) is published in the plugin's [GitHub repository](https://github.com/wan9yu/kong-plugin-argus-redact#60-second-demo) for end-to-end reproduction.

## Limitations (v0.1 preview)

The plugin is currently in v0.1 preview. The following are documented gaps that adopters should evaluate before use:

* **OpenAI Chat Completions only.** The plugin assumes `{messages: [{role, content: <string>}]}` on the request and `{choices: [{message: {content}}]}` on the response. Other vendor request shapes are out of scope for v0.1.
* **No streaming.** Requests with `stream: true` return HTTP 400 by design. Streaming support is on the v1 roadmap.
* **One HTTP call per `messages[].content`.** v0.1 calls `/redact` sequentially per message; a batched endpoint on the sidecar side is on the v1 wishlist.
* **Local string-substitution restore.** Since OpenResty's `body_filter_by_lua` phase forbids cosocket creation, the plugin does in-process key substitution rather than calling argus-redact's `/restore` endpoint from the response path. LLM rewrites that translate placeholders (for example, `张三` → `Zhang San`) are not currently restored.

The reasoning behind each limitation, the v0.1 cold-start profile, and end-to-end VM integration test results are documented in the plugin's [README](https://github.com/wan9yu/kong-plugin-argus-redact#what-it-doesnt-do-v01) and [`benchmarks/vm-test-2026-05-07.md`](https://github.com/wan9yu/kong-plugin-argus-redact/blob/main/benchmarks/vm-test-2026-05-07.md).
