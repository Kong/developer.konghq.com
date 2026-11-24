---
title: AI Rate Limit Alerts
description: Send a webhook alert when an AI Consumer uses 80% of its token quota on {{site.ai_gateway_name}}, before requests fail with HTTP 429.
url: "/cookbooks/ai-rate-limit-alerts/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.0'
categories:
  - cost-optimization
  - observability
featured: false
popular: false
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions a recipe-scoped {{site.ai_gateway}} and local data plane.

        1. Create a new personal access token by opening the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. You reuse the same token later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Open [webhook.site](https://webhook.site/) and copy your unique URL. The data plane sends the alert to this URL and reads it when the data plane starts, so export it before you run the quickstart script:

           ```bash
           export ALERT_WEBHOOK_URL='https://webhook.site/YOUR-UUID'
           ```

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script. The three `-e` settings let the Post-Function Policy send the alert:

           * `KONG_UNTRUSTED_LUA=on` turns off the Lua sandbox ([`untrusted_lua`](/ai-gateway/configuration/#untrusted-lua)). The policy uses `ngx.timer.at`, `ngx.shared`, and `os.getenv`, which the [sandbox](/ai-gateway/sandboxing/) doesn't allow in the default `strict` mode or in `lax` mode. It also loads `resty.http`, which only `lax` mode allows. See the warning in [Post-Function Policy](#post-function-policy).
           * `ALERT_WEBHOOK_URL` passes the webhook URL from your shell to the data plane container.
           * `KONG_NGINX_MAIN_ENV=ALERT_WEBHOOK_URL` adds the `env ALERT_WEBHOOK_URL;` directive to the NGINX `main` context ([NGINX injected directives](/ai-gateway/configuration/#nginx-injected-directives-section)). NGINX removes inherited environment variables unless an `env` directive keeps them ([NGINX documentation](https://nginx.org/en/docs/ngx_core_module.html#env)), so the policy can read the URL with `os.getenv` only with this setting.

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='ai-rate-limit-alerts-recipe'
           curl -Ls https://get.konghq.com/ai | \
             bash -s -- -k $KONNECT_TOKEN \
               -e KONG_UNTRUSTED_LUA=on \
               -e ALERT_WEBHOOK_URL \
               -e KONG_NGINX_MAIN_ENV=ALERT_WEBHOOK_URL
           ```

           This provisions an {{site.ai_gateway}} named `ai-rate-limit-alerts-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install **kongctl** from the [kongctl documentation](/kongctl/).
        1. Verify it's installed:

           ```bash
           kongctl version
           ```
    - title: AI Credentials
      content: |
        Export the credentials of the provider that the AI Model calls. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

        {% navtabs "Providers" %}
        {% navtab "OpenAI" %}
        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key:

           ```sh
           export OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
        {% endnavtab %}
        {% endnavtabs %}
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
  Send an alert to a webhook when an AI Consumer uses 80% of its token quota, so that you can act before {{site.ai_gateway_name}} rejects requests with HTTP 429. You'll set up:

  * A `/ai-rate-limit-alerts` chat endpoint with a token quota that the AI Rate Limiting Advanced Policy enforces
  * A Post-Function Policy that sends a JSON alert to a webhook at 80% of the quota, while requests still succeed
  * AI Consumer authentication, with the OpenAI API key kept in {{site.ai_gateway}}
---

## What this cookbook solves

Rate limits usually tell clients about a quota only when a request fails with `429`, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "A limit on the request count doesn't follow LLM cost. A short greeting and a long RAG prompt each count as one request, but the provider bills tokens."
    solution: "The AI Rate Limiting Advanced Policy counts the tokens that OpenAI reports for each request and returns `429` when the window has no tokens left."
  - problem: "A `429` is a hard stop. Operations and finance teams learn about the quota only after callers fail, too late to raise the quota or shed load."
    solution: "A Post-Function Policy sends a JSON alert to a webhook when 80% of the window is used. The request that crosses the threshold still gets `200`."
  - problem: "Each client must read the rate limit headers and repeat the same threshold logic in each language."
    solution: "The Post-Function Policy reads the rate limit headers on the data plane, so clients don't change."
  - problem: "An alert on every request after the threshold floods the channel."
    solution: "The Post-Function Policy sends at most one alert for each AI Consumer in 60 seconds."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends short chat requests until the token quota runs out, checks that the webhook received one alert, and sends one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI API key, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, an [AI Rate Limiting Advanced](/ai-gateway/policies/ai-rate-limiting-advanced/) Policy with a 50-token window, a [Post-Function](/ai-gateway/policies/post-function/) Policy that sends the alert, and an AI Model on `/ai-rate-limit-alerts` that answers to the `chat` alias.

Adopt the quickstart {{site.ai_gateway}} into a [kongctl namespace](/kongctl/). Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Select your provider. The tab exports `CHAT_MODEL`, the OpenAI model that the AI Model calls, then applies the configuration. The provider credentials and the webhook URL come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env var:

```bash
export CHAT_MODEL='gpt-4o-mini'
```

Apply the Kong configuration:

```bash
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
        value: !secret {source: !env 'OPENAI_TOKEN'}
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
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
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
    - |
      if not ngx.arg[2] then
        return
      end
      local rem, lim
      local headers = kong.response.get_headers() or {}
      for name, value in pairs(headers) do
        local lower = string.lower(name)
        if lower:find("x-ai-ratelimit-remaining-", 1, true)
           and not lower:find("reset", 1, true)
           and not lower:find("retry", 1, true) then
          rem = tonumber(value)
        elseif lower:find("x-ai-ratelimit-limit-", 1, true)
           and not lower:find("reset", 1, true)
           and not lower:find("retry", 1, true) then
          lim = tonumber(value)
        end
      end
      if not rem or not lim or lim <= 0 then
        return
      end
      local threshold = 80
      if (lim - rem) / lim * 100 < threshold then
        return
      end
      local consumer = kong.client.get_consumer() or {}
      local id = consumer.id or kong.client.get_forwarded_ip() or "anon"
      local dict = ngx.shared.kong
      if dict then
        local added = dict:add("ai-rate-alert:" .. id, 1, 60)
        if not added then
          return
        end
      end
      local url = os.getenv("ALERT_WEBHOOK_URL")
      if not url or url == "" then
        return
      end
      local username = consumer.username or "unknown"
      local ok, err = ngx.timer.at(0, function(premature)
        if premature then
          return
        end
        local http = require("resty.http")
        local cjson = require("cjson.safe")
        local httpc = http.new()
        httpc:set_timeout(3000)
        httpc:request_uri(url, {
          method = "POST",
          body = cjson.encode({
            text = string.format(
              "%s reached %s%% of the token quota. %s tokens remaining.",
              username,
              tostring(threshold),
              tostring(rem)
            ),
            username = username,
            remaining = rem,
            limit = lim,
            rate = lim - rem,
            threshold = threshold,
            window = "minute",
          }),
          headers = { ["Content-Type"] = "application/json" },
          ssl_verify = true,
        })
      end)
      if not ok then
        kong.log.err("ai-rate-alert timer: ", err)
      end
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
      model:
        body_param: model
        values:
        - chat
  targets:
  - name: !env 'CHAT_MODEL'
    provider: ai-rate-limit-alerts-provider
    config:
      type: openai
EOF

kongctl apply -f kong-recipe.yaml -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

{% endnavtab %}
{% endnavtabs %}

### Run the demo

The script sends `hi` chat requests with `max_tokens=1` until the 50-token window is empty, and prints the remaining tokens from the rate limit headers of each response. After the `429`, it checks the webhook.site inbox for the alert, then sends one request with an invalid API key. In the output, look for the `[THRESHOLD]` line, the `[BLOCKED] 429` line, and the `[WEBHOOK]` line.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""AI rate limit early-alert demo for Kong AI Gateway.

Sends short chat completions through Kong until the AI Consumer uses its
50-token, 60-second window. At 80% used, the Post-Function Policy sends a JSON
alert to ALERT_WEBHOOK_URL. When the window is empty, Kong returns 429. Then the
script sends one request with an invalid API key.

Expected output:
  - Early requests: [ALLOWED] 200, with the remaining tokens going down
  - At 80% used: [ALLOWED] 200 and [THRESHOLD], and the webhook inbox grows by one
  - After the quota: [BLOCKED] 429
  - Invalid API key: [BLOCKED] 401

Run: python demo.py (set PROXY_URL if the data plane is not at http://localhost:8000,
and CONSUMER_API_KEY if you changed the demo key). ALERT_WEBHOOK_URL must be your
webhook.site URL.
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
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
WEBHOOK_URL = os.getenv("ALERT_WEBHOOK_URL", "")
MODEL_ALIAS = "chat"
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
    return _c("32;1", s)


def RED(s: str) -> str:
    return _c("31;1", s)


def YELLOW(s: str) -> str:
    return _c("33;1", s)


def BLUE(s: str) -> str:
    return _c("34;1", s)


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


def make_client(api_key: str) -> OpenAI:
    return OpenAI(
        base_url=f"{PROXY_URL}/ai-rate-limit-alerts",
        api_key="unused",
        default_headers={"apikey": api_key},
    )


def chat(client: OpenAI):
    return client.chat.completions.with_raw_response.create(
        model=MODEL_ALIAS,
        messages=[{"role": "user", "content": "hi"}],
        max_tokens=1,
    )


def main() -> int:
    if not WEBHOOK_URL:
        print(RED("Set ALERT_WEBHOOK_URL to your webhook.site unique URL."))
        return 1

    client = make_client(API_KEY)
    token = webhook_token(WEBHOOK_URL)
    before = webhook_count(token)
    print(BOLD("[SETUP]"))
    print(f"  {DIM(f'proxy={PROXY_URL}/ai-rate-limit-alerts limit={LIMIT} threshold={THRESHOLD_PCT}%')}")
    print(f"  {DIM(f'webhook inbox before={before}')}")

    got_429 = False
    for i in range(1, 20):
        print(f"\n{BOLD('[REQUEST]')} chat {i}")
        try:
            raw = chat(client)
            headers = {k.lower(): v for k, v in raw.headers.items()}
            rem, lim = remaining_from(headers)
            used = (lim - rem) if rem is not None and lim else None
            pct = int(used / lim * 100) if used is not None and lim else None
            rem_s = f"{rem}/{lim}" if rem is not None and lim is not None else "n/a"
            used_s = f"{pct}%" if pct is not None else "n/a"
            remaining_s = f"remaining={rem_s}"
            print(f"  {GREEN('[ALLOWED] 200')} {BLUE(remaining_s)} {DIM('used=' + used_s)}")
            if pct is not None and pct >= THRESHOLD_PCT:
                print(f"  {YELLOW(f'[THRESHOLD] {THRESHOLD_PCT}% reached')}")
        except APIStatusError as err:
            print(f"  {RED(f'[BLOCKED] {err.status_code}')} {DIM(str(err.message)[:120])}")
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

    bad_key = "not-a-real-key"
    print(f"\n{BOLD('[REQUEST]')} invalid API key")
    print(f"  Trying apikey={bad_key!r}")
    try:
        chat(make_client(bad_key))
        print(f"  {RED('[ALLOWED]')} Kong accepted the invalid key")
        return 1
    except APIStatusError as err:
        print(f"  {RED(f'[BLOCKED] {err.status_code}')}")

    print(f"\n{GREEN('[OK]')} early alert fired before the 429")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
[SETUP]
  proxy=http://localhost:8000/ai-rate-limit-alerts limit=50 threshold=80%
  webhook inbox before=0

[REQUEST] chat 1
  [ALLOWED] 200 remaining=48/50 used=4%

[REQUEST] chat 2
  [ALLOWED] 200 remaining=39/50 used=22%

[REQUEST] chat 3
  [ALLOWED] 200 remaining=30/50 used=40%

[REQUEST] chat 4
  [ALLOWED] 200 remaining=21/50 used=57%

[REQUEST] chat 5
  [ALLOWED] 200 remaining=12/50 used=76%

[REQUEST] chat 6
  [ALLOWED] 200 remaining=3/50 used=94%
  [THRESHOLD] 80% reached

[REQUEST] chat 7
  [BLOCKED] 429 Error code: 429 - AI token rate limit exceeded for provider(s):

[WEBHOOK] inbox grew 0 -> 1

[REQUEST] invalid API key
  Trying apikey='not-a-real-key'
  [BLOCKED] 401

[OK] early alert fired before the 429
```
{: .no-copy-code .collapsible }

The remaining values depend on how many tokens OpenAI counts for each request. The webhook.site inbox shows one POST with a JSON body like the following:

```json
{
  "text": "ai-rate-limit-alerts-consumer reached 80% of the token quota. 3 tokens remaining.",
  "username": "ai-rate-limit-alerts-consumer",
  "remaining": 3,
  "limit": 50,
  "rate": 47,
  "threshold": 80,
  "window": "minute"
}
```
{:.no-copy-code}

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Token counting"
    evidence: "`remaining` goes down by the tokens of each request, 9 for each `hi` in this run, not by one for each request."
  - behavior: "Alert before the quota runs out"
    evidence: "Chat 6 reaches 94% used and still gets `200`. The `[WEBHOOK]` line shows that webhook.site received a POST."
  - behavior: "Hard limit"
    evidence: "Chat 7 gets `429` from the AI Rate Limiting Advanced Policy, because the window has fewer tokens left than the request needs."
  - behavior: "Authentication before the quota"
    evidence: "The invalid key gets `401`, and the request never reaches OpenAI."
{% endtable %}

To review the created entities, and per-consumer usage, open the `ai-rate-limit-alerts-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong authenticates the AI Consumer, checks the token window, and forwards the request to OpenAI. When Kong sends the response, the Post-Function Policy reads the rate limit headers and, at 80% used, starts a timer that sends the alert, so the client gets the response without waiting for the webhook.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as Client
    participant K as Kong AI Gateway
    participant O as OpenAI
    participant W as Webhook

    C->>K: POST /ai-rate-limit-alerts/chat/completions (apikey, model chat)
    activate K
    K->>K: Key Auth AI Auth Strategy identifies the AI Consumer (else 401)
    K->>K: AI Rate Limiting Advanced Policy checks the token window (else 429)
    K->>O: Request with the OpenAI key
    activate O
    O-->>K: Completion and token usage
    deactivate O
    K-->>C: 200 with the rate limit headers
    K->>K: Post-Function Policy computes the used share from the headers
    K->>W: Timer sends the JSON alert at 80% used, once in 60 seconds
    deactivate K
{% endmermaid %}
<!-- vale on -->

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use, and the Post-Function Policy puts its name in the alert.

The following settings configure the Key Auth AI Auth Strategy and the AI Consumer:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`key_names: [apikey]`"
    purpose: "Kong reads the key from the `apikey` header. Key Auth compares the whole header value, so it can't read a key from an `Authorization: Bearer` header. The note in [Run the demo](#run-the-demo) shows the workaround."
  - setting: "`hide_credentials: true`"
    purpose: "Kong removes the key before it forwards the request. OpenAI never sees the AI Consumer key."
  - setting: "`credentials[].api_key`"
    purpose: "The AI Consumer's key. The field is write-only, so it takes a `!secret` reference to `CONSUMER_API_KEY`, even for a demo value."
{% endtable %}

Kong adds `X-Consumer-Username` and related headers to the upstream request, not to the response. Per-consumer usage appears in {{site.konnect_short_name}} analytics.

### AI Rate Limiting Advanced Policy

The AI Rate Limiting Advanced Policy counts prompt and completion tokens, the unit that drives LLM cost. It allows 50 tokens in a 60-second window, which the demo uses up in a few requests. Kong counts a request's tokens after OpenAI answers, so concurrent requests can go over the limit. A request whose prompt is larger than the tokens left gets `429` before Kong calls OpenAI.

The following settings configure the AI Rate Limiting Advanced Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.policies[].limits`"
    purpose: "The token limit and the window size in seconds: `50` and `60`."
  - setting: "`window_type: fixed`"
    purpose: "Assigns each request to one 60-second bucket, so the quota restores at the end of the window. A `sliding` window weighs the current window against the previous one."
  - setting: "`identifier: consumer`"
    purpose: "Counts usage for each AI Consumer. In a test on runtime 2.3.1, two AI Consumers that called from the same machine shared one counter. This cookbook hasn't confirmed separate budgets for AI Consumers on different machines."
  - setting: "`tokens_count_strategy: total_tokens`"
    purpose: "Counts prompt and completion tokens. Other values count only prompt tokens, only completion tokens, or cost."
  - setting: "`hide_client_headers: false`"
    purpose: "Kong adds the limit and remaining headers to each response. The Post-Function Policy reads these headers, so with `true`, no alert is sent."
  - setting: "`strategy: local`"
    purpose: "Keeps the counters in memory on each data plane node. For several nodes, use `redis` so that the nodes share the counters."
{% endtable %}

### Post-Function Policy

The Post-Function Policy runs Lua code from its `config.body_filter` list while Kong sends the response body. It's listed on the AI Model, so it runs after authentication, and `kong.client.get_consumer()` returns the AI Consumer. The alert carries only counters and the AI Consumer name. Don't add prompts, responses, or keys to it, because the webhook receiver is outside Kong.

The following settings configure the Post-Function Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`body_filter`"
    purpose: "Runs the code for each chunk of the response body. `if not ngx.arg[2]` returns early until the last chunk, so the code runs once for each response, after Kong has set the rate limit headers."
  - setting: "`X-AI-RateLimit-Remaining-*` and `X-AI-RateLimit-Limit-*`"
    purpose: "The code reads both headers with any suffix and skips the reset and retry headers. The suffix depends on the window and the policy index, for example `-minute-policy-1`."
  - setting: "`local threshold = 80`"
    purpose: "The share of the limit, in percent, that triggers the alert. The code computes `(limit - remaining) / limit * 100`."
  - setting: "`ngx.shared.kong` and `dict:add(..., 1, 60)`"
    purpose: "Stores a key for each AI Consumer for 60 seconds. `add` fails when the key exists, so the code sends at most one alert for each AI Consumer in 60 seconds on each data plane node."
  - setting: "`os.getenv(\"ALERT_WEBHOOK_URL\")`"
    purpose: "Reads the webhook URL from the data plane environment. If the variable is empty, the code sends no alert."
  - setting: "`ngx.timer.at(0, ...)`"
    purpose: "Runs the POST in a zero-delay timer. OpenResty disables network sockets in the body filter phase, and recommends a zero-delay timer when the request doesn't need the result ([OpenResty documentation](https://github.com/openresty/lua-nginx-module#cosockets-not-available-everywhere))."
  - setting: "`resty.http` `request_uri`"
    purpose: "Sends the alert as a JSON POST with a 3-second timeout and TLS certificate verification (`ssl_verify = true`)."
  - setting: "Alert fields"
    purpose: "`text` (a summary), `username` (the AI Consumer name), `remaining`, `limit`, `rate` (the tokens used), `threshold`, and `window`."
{% endtable %}

{:.warning}
> `KONG_UNTRUSTED_LUA=on` turns off the Lua sandbox on the data plane. Lua code in every AI Policy on that data plane, not only this Post-Function Policy, then has complete access to the environment and to all modules, with no protections ([sandboxing](/ai-gateway/sandboxing/)). Use this setting only for this local demo, and don't use it on a data plane that serves other traffic.

### AI Model Provider and AI Model

The AI Model Provider holds the OpenAI API key and adds it to each request to OpenAI. The AI Model `ai-rate-limit-alerts-model` accepts OpenAI-format requests on `/ai-rate-limit-alerts`, answers to the `chat` alias, and lists both AI Policies.

The following settings configure the AI Model Provider and the AI Model:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The OpenAI API key, from `OPENAI_TOKEN`. Kong adds it to each request to OpenAI. The field is write-only, so {{site.konnect_short_name}} never returns it."
  - setting: "`config.route.model`"
    purpose: "Kong reads the `model` field of the request body (`body_param: model`) and matches it against `chat`. Another value, including `gpt-4o-mini`, matches no AI Model and returns `500` with `failed the initial dns/balancer resolve for 'ai-gateway.upstream.local'`."
  - setting: "`policies`"
    purpose: "Attaches the AI Rate Limiting Advanced Policy and the Post-Function Policy to the AI Model. A Post-Function Policy runs after the other AI Policies in each phase."
  - setting: "`access.auth_strategies`"
    purpose: "Each request must have a valid AI Consumer key."
  - setting: "`formats: [{type: openai}]` and `capabilities: [generate]`"
    purpose: "The AI Model accepts OpenAI-format chat completion requests."
  - setting: "`config.route.paths`"
    purpose: "`/ai-rate-limit-alerts`. The `generate` capability adds `/chat/completions`, so the endpoint is `/ai-rate-limit-alerts/chat/completions`."
  - setting: "`targets[].name`"
    purpose: "The OpenAI model, from `CHAT_MODEL`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes `/ai-rate-limit-alerts` from the path before it forwards the request."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default."
  - setting: "`config.response_streaming: allow`"
    purpose: "Clients can request streamed responses."
  - setting: "`config.logging.payloads: true`"
    purpose: "Kong logs request and response payloads. The default is `false`."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key and the OpenAI API key in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

The AI Rate Limiting Advanced Policy adds the following headers to each response:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-AI-RateLimit-Limit-minute-policy-1`"
    description: "The token limit for the 60-second window of the first entry in `config.policies`."
  - header: "`X-AI-RateLimit-Remaining-minute-policy-1`"
    description: "The tokens left in the current window. The demo and the Post-Function Policy compute the used share from this header and the limit header."
  - header: "`X-AI-RateLimit-Reset`"
    description: "The seconds until the quota is restored."
  - header: "`X-AI-RateLimit-Retry-After`"
    description: "On a `429` response, the seconds until the AI Consumer can send requests again. There is no plain `Retry-After` header."
{% endtable %}

## Variations and next steps

You can change or extend this configuration in the following ways:

{% table %}
columns:
  - title: Variation
    key: variation
  - title: How
    key: how
rows:
  - variation: "Change the quota or the threshold"
    how: "Change `limit` and `window_size` in the AI Rate Limiting Advanced Policy, or `local threshold = 80` in the Post-Function Policy, and re-apply the configuration from [Apply the Kong configuration](#apply-the-kong-configuration). For a daily quota, set `window_size: 86400`, and change `window = \"minute\"` in the alert to match."
  - variation: "Send the alert to Slack"
    how: "Before you run the quickstart script, export `ALERT_WEBHOOK_URL` with a Slack [incoming webhook](https://docs.slack.dev/messaging/sending-messages-using-incoming-webhooks/) URL. Slack posts the `text` field of the alert as the message."
  - variation: "Send the alert to PagerDuty"
    how: "Change the alert body in the Post-Function Policy to the PagerDuty Events API v2 format (`routing_key`, `event_action: trigger`, and a `payload` with `summary`, `source`, and `severity`), and set `ALERT_WEBHOOK_URL` to `https://events.pagerduty.com/v2/enqueue`. See [Send an alert event](https://docs.pagerduty.com/developer/send-alert-event)."
  - variation: "Share counters across data plane nodes"
    how: "Set `strategy: redis` and point the AI Rate Limiting Advanced Policy at a shared Redis instance. The 60-second alert suppression in `ngx.shared` stays on each node, so each node can send one alert."
  - variation: "Give each AI Consumer Group its own quota"
    how: "Set `identifier: consumer-group` on the AI Rate Limiting Advanced Policy and list the policy in the [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/)'s `policies`. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
  - variation: "Authenticate users with an identity provider"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumers. The AI Model, AI Model Provider, and AI Policies don't change. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta."
{% endtable %}

## Cleanup

The quickstart created an {{site.ai_gateway}} for this recipe only, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='ai-rate-limit-alerts-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

Leave the virtual environment and remove the files and environment variables that the recipe created:

```bash
deactivate
rm -rf .venv demo.py
unset CONSUMER_API_KEY CHAT_MODEL ALERT_WEBHOOK_URL
```

If you created the OpenAI API key only for this recipe, delete it in the [OpenAI dashboard](https://platform.openai.com/api-keys).
