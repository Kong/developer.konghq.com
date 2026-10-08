---
title: AI Rate Limit Alerts
description: Notify Slack, PagerDuty, or a webhook before a Consumer hits its AI token quota, instead of waiting for HTTP 429.
url: "/cookbooks/ai-rate-limit-alerts/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
canonical: true
works_on:
  - konnect
min_version:
  gateway: "3.14"
  ai-gateway: "2.0"
categories:
  - cost-optimization
  - observability
featured: false
popular: false

plugins:
  - key-auth
  - ai-rate-limiting-advanced
  - post-function
  - ai-model
  - ai-model-provider
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key, a webhook.site URL, and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: Kong Konnect
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped AI Gateway and local Data Plane. The runnable demo sends alerts with a [post-function](/ai-gateway/policies/post-function/) Policy to `DECK_WEBHOOK_URL`.

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Create a unique URL at [webhook.site](https://webhook.site/) and export it. The data plane reads this value when the post-function Policy sends the alert:

           ```bash
           export DECK_WEBHOOK_URL='https://webhook.site/YOUR-UUID'
           ```

        1. Set the recipe-scoped AI Gateway name and run the quickstart script. `KONG_UNTRUSTED_LUA=on` lets the post-function Policy call `resty.http`. `-e DECK_WEBHOOK_URL` sets the webhook URL on the container, and `KONG_NGINX_MAIN_ENV=DECK_WEBHOOK_URL` exposes it to nginx workers so `os.getenv` works inside post-function:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='ai-rate-limit-alerts-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN \
             -e KONG_UNTRUSTED_LUA=on \
             -e DECK_WEBHOOK_URL \
             -e KONG_NGINX_MAIN_ENV=DECK_WEBHOOK_URL
           ```

           This provisions an AI Gateway named `ai-rate-limit-alerts-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: OpenAI
      content: |
        This tutorial uses OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.0.0'
        ```
overview: |
  LLM quotas are measured in tokens, not request counts, so HTTP 429 often arrives after
  the budget is already gone. [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/)
  writes remaining and limit headers, but it has no built-in 80% notify field. A post-function
  Policy reads those headers on the {{site.konnect_product_name}} data plane and POSTs
  `DECK_WEBHOOK_URL` at 80% used. By the end you have a `/ai-rate-limit-alerts` chat endpoint
  that still returns 200 at 80%, notifies an external channel, and only returns 429 after the
  quota is exhausted.
---

## The problem

REST rate limits usually wait until the client exceeds the cap, then return 429. That is late
for LLM traffic:

- **Token spend is uneven.** A short greeting and a long RAG prompt both count as one HTTP
  request. The unit that matters is tokens, which the client cannot predict from request count.
- **429 is a hard stop.** Ops and finance want "about to hit the cap" so they can raise the
  quota or shed load before callers fail.
- **Per-app header polling does not scale.** The AI Rate Limiting Advanced Policy can expose
  remaining and limit headers. Every client must read them, and every language stack copies
  the same threshold logic.
- **Token windows have no built-in early-warning field.** The policy can enforce a hard cap
  and emit remaining/limit headers, but it does not POST an external channel at 80% used.

## The solution

Kong already writes `X-AI-RateLimit-Remaining-*` and `X-AI-RateLimit-Limit-*` after a chat
returns. A [post-function](/ai-gateway/policies/post-function/) AI Policy reads those headers after the
response body finishes and computes `(limit - remaining) / limit`. At 80% it POSTs
`DECK_WEBHOOK_URL` with `resty.http` via `ngx.timer.at`. Without post-function there is no 80% signal.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    autonumber
    participant C as Client
    participant DP as Kong AI Gateway
    participant LLM as OpenAI
    participant WH as webhook URL

    C->>DP: chat completions (apikey)
    Note over DP: key-auth Auth Strategy, then token window Policy
    alt quota remaining
        DP->>LLM: AI Model + Provider
        LLM-->>DP: 200 plus token usage
        Note over DP: post-function POST if used/limit >= 0.8
        DP->>WH: webhook POST (Konnect path)
        DP-->>C: 200
    else quota exhausted
        DP-->>C: 429
    end
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: key-auth Auth Strategy
    responsibility: Maps the `apikey` header to a Consumer for the rate-limit partition.
  - component: ai-rate-limiting-advanced Policy
    responsibility: Counts `total_tokens` per Consumer, sets remaining and limit headers, returns 429 when the window is empty.
  - component: post-function Policy
    responsibility: Computes 80% from those headers and POSTs the webhook to `DECK_WEBHOOK_URL`.
  - component: AI Model + Provider
    responsibility: Injects the OpenAI credential and proxies `/ai-rate-limit-alerts`.
{% endtable %}

## How it works

1. The client calls `/ai-rate-limit-alerts` with an `apikey`.
2. The key-auth AI Auth Strategy maps the key to a Consumer.
3. The ai-rate-limiting-advanced Policy counts `total_tokens` for that Consumer and writes remaining and limit headers. If the window is empty, Kong returns 429 and stops.
4. On a successful chat, the AI Model proxies OpenAI.
5. The post-function Policy runs in `body_filter`, computes percent used, and at 80% schedules a webhook POST to `DECK_WEBHOOK_URL`. The caller still receives 200.

### Key Auth: Consumer identity for the quota

The key-auth AI Auth Strategy identifies the caller so AI Rate Limiting Advanced
can partition by Consumer. The demo key is `demo-api-key`. Production should use one key per
application.

#### Configuration details

```yaml
ai_gateway_auth_strategies:
- type: key-auth
  config:
    key_names:
      - apikey
    hide_credentials: true
```
{:.no-copy-code}

**`key_names`** is the request header the client sends.  
**`hide_credentials`** strips the key before the request reaches OpenAI.

### AI Rate Limiting Advanced: token window and headers

The [ai-rate-limiting-advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy counts
`total_tokens` per Consumer. Set **`hide_client_headers`** to `false` so post-function can
read remaining and limit. The 50-token / 60-second window is small so the demo reaches 80% quickly.
In {{site.ai_gateway}} 2.0 the window lives under `config.policies[]` with a top-level `identifier`.

#### Configuration details

```yaml
ai_gateway_policies:
- type: ai-rate-limiting-advanced
  config:
    strategy: local
    identifier: consumer
    tokens_count_strategy: total_tokens
    hide_client_headers: false
    policies:
      - window_type: fixed
        limits:
          - limit: 50
            window_size: 60
```
{:.no-copy-code}

Use `strategy: redis` when more than one data plane shares the counter.

### Post-function: 80% signal

The [post-function](/ai-gateway/policies/post-function/) Policy runs in `body_filter` (`eof`). It scans
`X-AI-RateLimit-Remaining-*` and `X-AI-RateLimit-Limit-*` (suffixes vary by mode)
after `total_tokens` headers exist. At 80% used it schedules `resty.http` with
`ngx.timer.at` (`cosockets` are not available in filter phases) and POSTs `DECK_WEBHOOK_URL`.

**`threshold = 80`** is percent used. **`dict:add(..., 1, 60)`** snoozes repeat alerts for 60 seconds.
`resty.http` needs `KONG_UNTRUSTED_LUA=on`. The data plane also needs
`KONG_NGINX_MAIN_ENV=DECK_WEBHOOK_URL` so workers can read `DECK_WEBHOOK_URL`.

### AI Model: chat proxy

The AI Model injects the OpenAI key through its Provider and proxies the chat on
`/ai-rate-limit-alerts`.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/latest/kong-enterprise/secrets-management/) using {%raw%}`{vault://backend/key}`{%endraw%} references rather than environment variables.

Do not send secrets, prompts, or full messages in the webhook body.

## Apply the Kong configuration

The following configuration creates an AI Model Provider, a key-auth AI Auth Strategy and Consumer, an ai-rate-limiting-advanced Policy, a post-function Policy for the 80% webhook, and one AI Model on `/ai-rate-limit-alerts`. Every resource is scoped using a kongctl namespace. See the [kongctl documentation](/kongctl/) for more on federated configuration management.

First, adopt the quickstart {{site.ai_gateway}} into a kongctl namespace so the following apply commands can manage it.

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Adoption stamps the `KONGCTL-namespace` label on the {{site.ai_gateway}}.

Export the demo Consumer's API key and chat model. `KONNECT_CONTROL_PLANE_NAME`, `KONNECT_TOKEN`, `DECK_OPENAI_TOKEN`,
`AI_GATEWAY_ID`, and `DECK_WEBHOOK_URL` are already set in Prerequisites.

```bash
export DECK_CONSUMER_API_KEY='demo-api-key'
export DECK_CHAT_MODEL='gpt-4o-mini'
```

Apply the Kong configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: ai-rate-limit-alerts-recipe
ai_gateway_model_providers:
- ref: ai-rate-limit-alerts-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ai-rate-limit-alerts-provider
  display_name: ai-rate-limit-alerts
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: ai-rate-limit-alerts-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ai-rate-limit-alerts-auth
  display_name: ai-rate-limit-alerts key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: ai-rate-limit-alerts-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ai-rate-limit-alerts-consumer
  display_name: ai-rate-limit-alerts demo consumer
  type: api-key
  credentials:
  - ref: ai-rate-limit-alerts-credential
    name: ai-rate-limit-alerts-credential
    display_name: ai-rate-limit-alerts demo API key
    type: api-key
    api_key: !secret {source: !env 'DECK_CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: ai-rate-limit-alerts-rla
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ai-rate-limit-alerts-rla
  display_name: ai-rate-limit-alerts token window
  type: ai-rate-limiting-advanced
  config:
    strategy: local
    identifier: consumer
    tokens_count_strategy: total_tokens
    hide_client_headers: false
    policies:
    - window_type: fixed
      limits:
      - limit: 50
        window_size: 60
- ref: ai-rate-limit-alerts-notify
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ai-rate-limit-alerts-notify
  display_name: ai-rate-limit-alerts 80% webhook
  type: post-function
  config:
    body_filter:
    - "if not ngx.arg[2] then\n  return\nend\nlocal rem, lim\nlocal headers = kong.response.get_headers()\
      \ or {}\nfor name, value in pairs(headers) do\n  local lower = string.lower(name)\n\
      \  if lower:find(\"x-ai-ratelimit-remaining-\", 1, true)\n     and not lower:find(\"\
      reset\", 1, true)\n     and not lower:find(\"retry\", 1, true) then\n    rem\
      \ = tonumber(value)\n  elseif lower:find(\"x-ai-ratelimit-limit-\", 1, true)\n\
      \     and not lower:find(\"reset\", 1, true)\n     and not lower:find(\"retry\"\
      , 1, true) then\n    lim = tonumber(value)\n  end\nend\nif not rem or not lim\
      \ or lim <= 0 then\n  return\nend\nlocal threshold = 80\nif (lim - rem) / lim\
      \ * 100 < threshold then\n  return\nend\nlocal consumer = kong.client.get_consumer()\
      \ or {}\nlocal id = consumer.id or kong.client.get_forwarded_ip() or \"anon\"\
      \nlocal dict = ngx.shared.kong\nif dict then\n  local added = dict:add(\"ai-rate-alert:\"\
      \ .. id, 1, 60)\n  if not added then\n    return\n  end\nend\nlocal url = os.getenv(\"\
      DECK_WEBHOOK_URL\")\nif not url or url == \"\" then\n  return\nend\nlocal username\
      \ = consumer.username or \"unknown\"\nlocal ok, err = ngx.timer.at(0, function(premature)\n\
      \  if premature then\n    return\n  end\n  local http = require(\"resty.http\"\
      )\n  local cjson = require(\"cjson.safe\")\n  local httpc = http.new()\n  httpc:set_timeout(3000)\n\
      \  httpc:request_uri(url, {\n    method = \"POST\",\n    body = cjson.encode({\n\
      \      text = string.format(\n        \"%s reached %s%% of the token quota.\
      \ %s tokens remaining.\",\n        username,\n        tostring(threshold),\n\
      \        tostring(rem)\n      ),\n      username = username,\n      remaining\
      \ = rem,\n      limit = lim,\n      rate = lim - rem,\n      threshold = threshold,\n\
      \      window = \"minute\",\n    }),\n    headers = { [\"Content-Type\"] = \"\
      application/json\" },\n    ssl_verify = true,\n  })\nend)\nif not ok then\n\
      \  kong.log.err(\"ai-rate-alert timer: \", err)\nend\n"
ai_gateway_models:
- ref: ai-rate-limit-alerts-model
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: ai-rate-limit-alerts-model
  display_name: ai-rate-limit-alerts
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - ai-rate-limit-alerts-auth
  policies:
  - ai-rate-limit-alerts-rla
  - ai-rate-limit-alerts-notify
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    logging:
      payloads: true
    route:
      paths:
      - /ai-rate-limit-alerts
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'DECK_CHAT_MODEL'
    provider: ai-rate-limit-alerts-provider
    config:
      type: openai
EOF
{% endraw -%}

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

The demo sends short `hi` chats with `max_tokens=1` until the 50-token window is empty. Watch
`X-AI-RateLimit-Remaining-*` fall, then confirm the webhook received a POST at 80%. After
the quota, Kong returns 429.

{:.info}
> The OpenAI SDK sends `api_key` as `Authorization: Bearer`. This demo uses
> `default_headers={"apikey": ...}` instead. See
> [Authenticate OpenAI SDK clients with Key Auth](/how-to/authenticate-openai-sdk-clients-with-key-auth/).

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""AI rate limit early-alert demo.

Sends short chat completions through Kong until the Consumer uses 80% of a
50-token / 60-second window. Kong should POST a JSON alert to DECK_WEBHOOK_URL
at that threshold, then return HTTP 429 after the quota is exhausted.

Expected output:
  - Early requests -> 200, remaining headers well above 20%
  - At 80% used    -> 200, webhook inbox grows
  - After the quota -> 429

Run:
  export PROXY_URL=http://localhost:8000
  export DECK_WEBHOOK_URL=https://webhook.site/YOUR-UUID
  python demo.py
"""

from __future__ import annotations

import json
import os
import sys
import time
import urllib.error
import urllib.parse
import urllib.request

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = "demo-api-key"
WEBHOOK_URL = os.getenv("DECK_WEBHOOK_URL", "")
LIMIT = 50
THRESHOLD_PCT = 80

_USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def _c(code: str, s: str) -> str:
    return f"\033[{code}m{s}\033[0m" if _USE_COLOR else s


def BOLD(s: str) -> str:
    return _c("1", s)


def DIM(s: str) -> str:
    return _c("2", s)


def GREEN(s: str) -> str:
    return _c("32", s)


def RED(s: str) -> str:
    return _c("31", s)


def YELLOW(s: str) -> str:
    return _c("33", s)


def BLUE(s: str) -> str:
    return _c("34", s)


def remaining_from(headers: dict[str, str]) -> tuple[int | None, int | None]:
    rem = lim = None
    for raw_name, value in headers.items():
        name = raw_name.lower()
        if name.startswith("x-ai-ratelimit-remaining-") and "reset" not in name and "retry" not in name:
            rem = int(float(value))
        elif name.startswith("x-ai-ratelimit-limit-") and "reset" not in name and "retry" not in name:
            lim = int(float(value))
    return rem, lim


def webhook_token(url: str) -> str:
    path = urllib.parse.urlparse(url).path.strip("/")
    return path.split("/")[0] if path else ""


def webhook_count(token: str) -> int:
    if not token:
        return 0
    req = urllib.request.Request(
        f"https://webhook.site/token/{token}/requests?sorting=newest&per_page=20",
        headers={"Accept": "application/json"},
    )
    try:
        with urllib.request.urlopen(req, timeout=10) as resp:
            body = json.load(resp)
    except (urllib.error.URLError, json.JSONDecodeError, TimeoutError):
        return 0
    return len(body.get("data") or [])


def make_client() -> OpenAI:
    return OpenAI(
        base_url=f"{PROXY_URL}/ai-rate-limit-alerts",
        api_key="unused",
        default_headers={"apikey": API_KEY},
    )


def main() -> int:
    if not WEBHOOK_URL:
        print(RED("Set DECK_WEBHOOK_URL to your webhook.site unique URL."))
        return 1

    client = make_client()
    token = webhook_token(WEBHOOK_URL)
    before = webhook_count(token)
    print(BOLD("[SETUP]"))
    print(f"  {DIM(f'proxy={PROXY_URL}/ai-rate-limit-alerts limit={LIMIT} threshold={THRESHOLD_PCT}%')}")
    print(f"  {DIM(f'webhook inbox before={before}')}")

    got_429 = False
    for i in range(1, 20):
        print(f"\n{BOLD('[REQUEST]')} chat {i}")
        try:
            raw = client.chat.completions.with_raw_response.create(
                model="gpt-4o-mini",
                messages=[{"role": "user", "content": "hi"}],
                max_tokens=1,
            )
            headers = {k.lower(): v for k, v in raw.headers.items()}
            rem, lim = remaining_from(headers)
            used = (lim - rem) if rem is not None and lim else None
            pct = int(used / lim * 100) if used is not None and lim else None
            rem_s = f"{rem}/{lim}" if rem is not None and lim is not None else "n/a"
            used_s = f"{pct}%" if pct is not None else "n/a"
            remaining_s = f"remaining={rem_s}"
            print(f"  {GREEN('200')} {BLUE(remaining_s)} {DIM('used=' + used_s)}")
            if pct is not None and pct >= THRESHOLD_PCT:
                print(f"  {YELLOW(f'THRESHOLD {THRESHOLD_PCT}% reached')}")
        except APIStatusError as err:
            print(f"  {RED(str(err.status_code))} {DIM(str(err.message)[:120])}")
            if err.status_code == 429:
                got_429 = True
                break

    hit = False
    after = before
    for _ in range(15):
        after = webhook_count(token)
        if after > before:
            hit = True
            break
        time.sleep(1)

    if hit:
        print(f"\n{GREEN('[WEBHOOK]')} inbox grew {before} -> {after}")
    else:
        print(f"\n{RED('[WEBHOOK]')} no new POST at {WEBHOOK_URL}")
        return 1

    if not got_429:
        print(RED("[FAIL] expected HTTP 429 after the token quota"))
        return 1

    print(f"\n{GREEN('[OK]')} early alert fired before the 429")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
```
{:.collapsible}

Run it:

```bash
export PROXY_URL=http://localhost:8000
python demo.py
```

Example output:

```text
[SETUP]
  proxy=http://localhost:8000/ai-rate-limit-alerts limit=50 threshold=80%
  webhook inbox before=0

[REQUEST] chat 1
  200 remaining=42/50 used=16%

[REQUEST] chat 5
  200 remaining=10/50 used=80%
  THRESHOLD 80% reached

[REQUEST] chat 7
  429 API rate limit exceeded

[WEBHOOK] inbox grew 0 -> 1

[OK] early alert fired before the 429
```
{:.no-copy-code}

Example webhook body:

```json
{
  "text": "demo-app reached 80% of the token quota. 10 tokens remaining.",
  "username": "demo-app",
  "remaining": 10,
  "limit": 50,
  "rate": 40,
  "threshold": 80,
  "window": "minute"
}
```
{:.no-copy-code}

Exact remaining values depend on how many tokens OpenAI reports for `hi`. The script looks
for used/limit at or above 80%, then for HTTP 429.


### What happened

1. **Key Auth** mapped `apikey: demo-api-key` to the demo Consumer.
2. **AI Rate Limiting Advanced** counted `total_tokens` and updated remaining/limit headers.
3. **Post-function** POSTed once at 80%. Further chats in the same 60 seconds are snoozed.
4. **429** arrived only after the window was empty. The caller still received 200 at 80%.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `ai-rate-limit-alerts-recipe`. The recipe created an AI Model Provider, one AI Model on `/ai-rate-limit-alerts`, a key-auth AI Auth Strategy, an ai-rate-limiting-advanced Policy, a post-function Policy, and a Consumer with a demo API key, all scoped by the kongctl namespace applied above.

For platform-wide traffic analysis across every {{site.ai_gateway}}, head to the **Observability** L1 menu in Konnect.

## Variations and next steps

**Raise the quota.** Change `limits.limit` and `window_size`, or edit `local threshold = 80`.

**Point the webhook at Slack or PagerDuty.** Format `text` for Slack Incoming Webhooks, or
switch the body to the PagerDuty Events API. Do not include prompts or API keys.

**Use Redis** when more than one data plane shares counters. See
[AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/).

**Combine with cost-based limits.** See [LLM Cost Optimization](/cookbooks/llm-cost-optimization/).

## Cleanup

The recipe's kongctl namespace scoped all resources, so this teardown removes only this recipe's configuration. Tear down the local Data Plane and delete the {{site.ai_gateway}} from Konnect:

```bash
export KONNECT_CONTROL_PLANE_NAME='ai-rate-limit-alerts-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```
