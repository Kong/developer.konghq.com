# llms-full.txt eval — agent task comparison

This doc records an informal eval comparing five Claude Code setups on a single Kong configuration task. 

**Date**: 2026-05-12
**Task** (single prompt, identical across runs):

> Publish an API via Kong Gateway and rate limit it.

**Method**: Five fresh sub-agent contexts spawned via Claude Code's Agent tool. Same prompt, different setups. Wall-clock and tool-call counts pulled from the harness.

> Caveat: these are isolated sub-agent runs, not separate `claude` CLI sessions. Numbers are directionally meaningful but not identical to a terminal stopwatch. A real CLI run has additional overhead (startup, MCP warm-up, file system) — expect ~5–15s higher across the board.

## Headline comparison

| # | Setup | Wall clock | Tool calls | Tokens | Notes |
|---|---|---|---|---|---|
| 1 | **Cold** (no docs, no MCP) | 17.5s | 2 | 19.5K | Generic self-hosted Kong, made-up localhost defaults |
| 2 | **LLM-mode docs** (per-page `.md`) | 58.8s | 9 (6–7 WebFetch) | 24.3K | Multi-page fetch; 2 of 7 fetches returned 404 |
| 3 | **LLM-mode + Konnect MCP** | 56.1s | 8 (6 MCP) | 27.2K | Bypassed docs entirely; MCP schema introspection was enough; output is Konnect-native |
| 4 | **Megafile + guardrails** | **49.1s** | 5 | 24.8K | One curl download, 3 grep/sed extractions |
| 5 | **Megafile, naive WebFetch (no guardrails)** | ~12s to **fail** | 1 WebFetch | 20.5K | WebFetch returned synthetic 404; agent could not produce an answer |

## Per-run tool-call breakdown

### Run 1 — Cold (2 calls)
- `Bash: date +%s` — START
- `Bash: date +%s` — END

No web, no search, no docs. Straight from prompt to answer using model intuition only.

### Run 2 — LLM-mode docs (9 total; 8 visible)
- `Bash: date +%s` — START
- `WebFetch: https://developer.konghq.com/llms.txt`
- `WebFetch: https://developer.konghq.com/how-to/get-started-with-rate-limiting/.md` — **404** (bad URL: trailing `/.md`)
- `WebFetch: https://developer.konghq.com/gateway/get-started/.md` — **404** (same)
- `WebFetch: https://developer.konghq.com/plugins/rate-limiting/`
- `WebFetch: https://developer.konghq.com/gateway/`
- `WebFetch: https://developer.konghq.com/gateway/entities/service/`
- `WebFetch: https://developer.konghq.com/gateway/entities/route/`
- `Bash: date +%s` — END

### Run 3 — LLM-mode + Konnect MCP (8 calls)
- `Bash: date +%s` — START
- `mcp__Konnect__search` × 2–3 — keyword search across the Konnect schema
- `mcp__Konnect__get_schema` × 2 — pull the schema for service/route/plugin endpoints
- `mcp__Konnect__execute` × 1–2 — read-only calls only (e.g. `list_control_planes`, `list_service`)
- `Bash: date +%s` — END

Zero WebFetches — MCP introspection was sufficient; the agent never opened the docs site.

### Run 4 — Megafile + guardrails (5 calls)
- `Bash: date +%s` — START
- `Bash: curl + ls` — download `llms-full.txt` (30 MB) to `/tmp/kong-megafile.md`, confirm size
- `Bash: grep -n …` — locate the rate-limiting section anchor
- `Bash: sed -n 'X,Yp' …` — extract a ~280-line range around the walkthrough
- `Bash: date +%s` — END

~280 lines pulled into context out of ~8M tokens in the file.

### Run 5 — Naive WebFetch on megafile (failed in ~12s)
Two attempts confirmed the same behavior:

- `WebFetch: https://.../llms-full.txt` →
  `"The server returned HTTP 404 Not Found. The response body was not retrieved."`
- `curl -sI` on the same URL during the run: **HTTP/2 200, content-length 31833314**
- Sanity check `WebFetch` on a small page on the same host: **succeeded** (~150 tokens back)

**WebFetch returns a synthetic 404 when the response body is too large.** The 404 is not real; the file is there. WebFetch's own size guard refuses to return content above some threshold (well below 30 MB), and surfaces that as a misleading "404 Not Found" error rather than a clear "response too large" message.

