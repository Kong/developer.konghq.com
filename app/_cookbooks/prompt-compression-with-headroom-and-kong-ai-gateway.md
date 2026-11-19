---
title: Prompt Compression with Headroom
description: Compress tool results in agent requests with the AI Prompt Compressor Policy and Headroom, and compare a compressed endpoint with an uncompressed one on {{site.ai_gateway_name}}.
url: "/cookbooks/prompt-compression-with-headroom-and-kong-ai-gateway/"
content_type: cookbook
layout: cookbook
products:
  - ai-gateway
tools:
  - kongctl
works_on:
  - konnect
min_version:
  ai-gateway: '2.2'
categories:
  - cost-optimization
featured: true
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

        1. Set the recipe-scoped {{site.ai_gateway}} name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='prompt-compression-with-headroom-and-kong-ai-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           This provisions an {{site.ai_gateway}} named `prompt-compression-with-headroom-and-kong-ai-gateway-recipe`, a local data plane connected to it, and prints `export` lines for the rest of the session vars, including `AI_GATEWAY_ID`. Paste those into your shell when prompted.
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
        Export the credentials of the provider that both endpoints call. The provider's tab in [Apply the Kong configuration](#apply-the-kong-configuration) reads these variables.

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
    - title: Headroom
      content: |
        The [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy sends each conversation to [Headroom](https://github.com/headroomlabs-ai/headroom) 0.37.0 or later, which compresses it. You can use a [local Headroom installation](https://docs.headroomlabs.ai/docs/installation) or [Headroom Enterprise](https://www.headroomlabs.ai/). In both cases, the data plane must be able to connect to Headroom. For more information, see [Headroom compressor service](/ai-gateway/policies/ai-prompt-compressor/#headroom-compressor-service).

        By default, Headroom answers `/v1/compress` requests only from loopback callers and returns `404` to all other callers. `HEADROOM_COMPRESS_ALLOW_REMOTE=1` lets the data plane container call Headroom, and `HEADROOM_PROXY_TOKEN` sets the token that callers must send.

        1. Export your Headroom proxy token. Kong sends this token to Headroom on each call. If you start Headroom in the following steps, you can use any value:

           ```sh
           export HEADROOM_PROXY_TOKEN='YOUR_HEADROOM_PROXY_TOKEN'
           ```

        1. If you don't have a Headroom instance, open a second terminal on the machine that runs the quickstart, and export the same `HEADROOM_PROXY_TOKEN` there. Then install Headroom in a virtual environment. Headroom requires Python 3.10 or later:

           ```bash
           python3 -m venv .venv-headroom
           source .venv-headroom/bin/activate
           pip install 'headroom-ai[proxy]'
           ```

        1. In the second terminal, start Headroom on port `8787`. Headroom prints a log line for each request. Keep the terminal open:

           ```bash
           HEADROOM_COMPRESS_ALLOW_REMOTE=1 headroom proxy --port 8787
           ```

        1. In your first terminal, check that Headroom is running:

           ```bash
           curl http://localhost:8787/livez
           ```

           The response contains `"status":"healthy"`:

           ```text
           {"service":"headroom-proxy","status":"healthy","alive":true,"version":"0.41.0","timestamp":"2026-10-21T00:47:39.832326Z","uptime_seconds":553.888,"loop_health":{"status":"healthy","known_failures":0,"last_known_failure":null}}
           ```
           {:.no-copy-code}

        1. Export the URL of the Headroom `/v1/compress` endpoint, as the data plane container reaches it. On Docker Desktop, the container reaches a Headroom instance on the same machine at `host.docker.internal`:

           ```sh
           export HEADROOM_COMPRESSOR_URL='http://host.docker.internal:8787/v1/compress'
           ```

           If Headroom runs on another host, use the address of that host with the same path, for example `https://headroom.example.com/v1/compress`.
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Set up an isolated environment:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.51.0'
        ```
overview: |
  Compress the tool results in agent requests with Headroom before {{site.ai_gateway_name}} forwards them to OpenAI, and measure the savings against an uncompressed endpoint. You'll set up:

  * A `/compressed` endpoint where the AI Prompt Compressor Policy sends each conversation to Headroom
  * An `/uncompressed` endpoint that forwards the same requests unchanged, for comparison
  * AI Consumer authentication on both endpoints, with the OpenAI API key kept in {{site.ai_gateway}}
---

## What this cookbook solves

Agents send each tool result back to the model on every later turn of a conversation, and the provider bills those tokens each time, which causes the following problems:

{% table %}
columns:
  - title: Problem
    key: problem
  - title: Solution
    key: solution
rows:
  - problem: "Tool results are large structured data, such as JSON records, logs, and search output. A tool call that returns 200 log records adds about 10,000 tokens, and each record repeats each field name."
    solution: "The AI Prompt Compressor Policy sends each conversation to Headroom, which rewrote 200 JSON log records as a table with one header line. OpenAI counted about half the input tokens."
  - problem: "Chat completion APIs don't store the conversation, so each request carries the full history, including earlier tool results, and the provider bills them on each turn."
    solution: "Kong compresses each request, including the earlier tool results in later turns. In the demo, the second turn also uses about half the input tokens."
  - problem: "OpenAI bills less for the start of a prompt that matches a recent request ([prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching)). Compression that rewrites earlier messages differently on each turn changes the start of the prompt and loses this discount."
    solution: "Headroom keeps a session for each conversation and returns the earlier turns unchanged, so the start of the prompt stays the same. In the demo, OpenAI served 4,992 of 5,248 input tokens of the second turn from its cache."
  - problem: "Compression in each agent means a compression library and configuration in each language and framework."
    solution: "The policy runs on the data plane for each AI Model that lists it. Agents keep sending standard OpenAI-format requests."
  - problem: "Compressed content can be missing records or use a different format, and the response doesn't show what the model received."
    solution: "The `uncompressed` AI Model serves the same requests without the policy, so you can compare the input tokens and the answers of the two endpoints."
{% endtable %}

## Try it out

Apply the configuration, then run a demo script that sends an agent conversation with a large tool result to both endpoints, compares the input tokens that OpenAI counts, and sends one request with an invalid API key.

### Apply the Kong configuration

The configuration creates an AI Model Provider with your OpenAI API key, a Key Auth AI Auth Strategy, an AI Consumer with a demo API key, an AI Prompt Compressor Policy that points to your Headroom instance, and two AI Models that call the same OpenAI model: `compressed` with the policy, and `uncompressed` without it.

Adopt the quickstart {{site.ai_gateway}} into a [kongctl namespace](/kongctl/). Adoption adds the `KONGCTL-namespace` label to the {{site.ai_gateway}}. If the {{site.ai_gateway}} already has the label, kongctl prints an error and makes no changes, and you can continue:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Export the demo AI Consumer's API key. The credential's `api_key` field is write-only, so its value must come from an environment variable, even for a fixed demo key:

```bash
export CONSUMER_API_KEY='demo-api-key'
```

Select your provider. The tab exports `CHAT_MODEL`, the OpenAI model that both AI Models call, then applies the configuration. The provider credentials, the Headroom URL, and the Headroom proxy token come from the prerequisites.

{% navtabs "Providers" %}
{% navtab "OpenAI" %}

Export the model env var:

```bash
export CHAT_MODEL='gpt-4.1-mini'
```

Apply the Kong configuration:

```bash
cat <<'EOF' > kong-recipe.yaml
_defaults:
  kongctl:
    namespace: prompt-compression-with-headroom-and-kong-ai-gateway-recipe
ai_gateway_model_providers:
- ref: headroom-provider
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: headroom-provider
  display_name: headroom provider
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: !secret {source: !env 'OPENAI_TOKEN'}
ai_gateway_auth_strategies:
- ref: headroom-auth
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: headroom-auth
  display_name: headroom key auth
  type: key-auth
  config:
    key_names:
    - apikey
    hide_credentials: true
ai_gateway_consumers:
- ref: headroom-consumer
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: headroom-consumer
  display_name: headroom demo consumer
  type: api-key
  credentials:
  - ref: headroom-credential
    name: headroom-credential
    display_name: headroom demo API key
    type: api-key
    api_key: !secret {source: !env 'CONSUMER_API_KEY'}
ai_gateway_policies:
- ref: headroom-compressor
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: headroom-compressor
  display_name: Headroom prompt compressor
  type: ai-prompt-compressor
  enabled: true
  global: false
  config:
    provider: headroom
    compressor_url: !env 'HEADROOM_COMPRESSOR_URL'
    timeout: 45000
    stop_on_error: true
    headroom:
      proxy_token: !env 'HEADROOM_PROXY_TOKEN'
ai_gateway_models:
- ref: compressed
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: compressed
  display_name: Compressed (Headroom)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - headroom-auth
  policies:
  - headroom-compressor
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    route:
      paths:
      - /compressed
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: headroom-provider
    config:
      type: openai
- ref: uncompressed
  ai_gateway: !lookup {id: !env 'AI_GATEWAY_ID'}
  name: uncompressed
  display_name: Uncompressed (baseline)
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  access:
    auth_strategies:
    - headroom-auth
  policies: []
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    route:
      paths:
      - /uncompressed
      protocols:
      - http
      - https
      methods:
      - POST
      - OPTIONS
      strip_path: true
  targets:
  - name: !env 'CHAT_MODEL'
    provider: headroom-provider
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

The script plays an agent that has run a tool named `get_logs`. The script generates the tool result itself: 200 log records as JSON, three of them errors. The conversation contains the following four messages:

{% table %}
columns:
  - title: Message
    key: message
  - title: Role
    key: role
  - title: Content
    key: content
rows:
  - message: "1"
    role: "`user`"
    content: "Pull the last 200 log entries for our services."
  - message: "2"
    role: "`assistant`"
    content: "A tool call: run `get_logs` with a limit of 200."
  - message: "3"
    role: "`tool`"
    content: "The tool result: 200 log records as JSON, 25,540 characters."
  - message: "4"
    role: "`user`"
    content: "Which log entries are errors? List each id, service, and message."
{% endtable %}

In each step, the script sends the same messages to `/uncompressed` and then to `/compressed`, and prints the input tokens that OpenAI counted for each request (`usage.prompt_tokens`). Input tokens are everything the model reads for a request, which is the whole conversation:

1. Step 1 sends the four messages.
1. Step 2 asks a follow-up question in the same conversation. Like an agent, the script sends the whole conversation again, including the original 200 log records, with the same `x-session-id` header as step 1.
1. Step 3 starts a new conversation with one short question and no tool result.
1. Step 4 sends the short question to `/compressed` with an invalid API key.

In the output, compare the `input tokens` of the two endpoints and the `Answer from /compressed` with the `Expected` line.

{:.info}
> The demo passes the API key in `default_headers` because the OpenAI SDK always sends `api_key` as an `Authorization: Bearer` header. To let clients use `api_key` directly, add a global [Pre-Function](/ai-gateway/policies/pre-function/) Policy (`global: true`) that copies the Bearer token to the `apikey` header. A global Pre-Function Policy runs before authentication, while one attached to the AI Model runs after it.

Create the demo script:

```bash
cat <<'EOF' > demo.py
"""Compare input tokens with and without Headroom compression on Kong AI Gateway.

The script plays the part of an agent that has used a tool named get_logs.
get_logs isn't a real tool: the script generates 200 log records as its result.

The script sends the same conversation to two endpoints and prints how many input
tokens OpenAI counted for each one. Input tokens are everything the model reads for a
request, the whole conversation; OpenAI reports them as usage.prompt_tokens.

  /uncompressed  forwards the conversation to OpenAI unchanged.
  /compressed    sends the conversation to Headroom first, then forwards Headroom's version.

It runs four steps:

  Step 1  The conversation right after the tool ran: the user's request, the
          assistant's tool call, the tool result (200 log records in JSON), and a
          question about the records.
          Expected: /compressed sends about half the input tokens, and its answer
          lists the three error records.
  Step 2  The next request in the same conversation, with the same session ID.
          Expected: the savings carry over to the next turn, and the answer is correct.
  Step 3  A new conversation with one short question and no tool result.
          Expected: the same input tokens on both endpoints.
  Step 4  The short question with an invalid API key.
          Expected: [BLOCKED] 401 from Kong.

Run: python demo.py (set PROXY_URL if the data plane is not at http://localhost:8000,
and CONSUMER_API_KEY if you changed the demo key).
"""

import json
import os
import random
import sys
import uuid

from openai import APIStatusError, OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
API_KEY = os.getenv("CONSUMER_API_KEY", "demo-api-key")
USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def color(code, text):
    return f"\033[{code}m{text}\033[0m" if USE_COLOR else text


def bold(text):
    return color("1", text)


def ask(endpoint, messages, session_id, api_key=API_KEY):
    """Send the messages to /uncompressed or /compressed. Returns the response and Kong's latency."""
    # Kong reads the AI Consumer key from the apikey header and adds the OpenAI API key from
    # the AI Model Provider. The SDK requires an api_key value, but Kong never uses it.
    client = OpenAI(
        base_url=f"{PROXY_URL}/{endpoint}",
        api_key="unused",
        default_headers={"apikey": api_key},
    )
    raw = client.chat.completions.with_raw_response.create(
        model=endpoint,  # the AI Model's name, which matches its path
        messages=messages,
        temperature=0,
        extra_headers={"x-session-id": session_id},  # Headroom keeps one session per ID
    )
    return raw.parse(), raw.headers.get("x-kong-proxy-latency", "?")


def run_step(title, messages, session_id):
    """Send the same messages to both endpoints and print the results. Returns the /compressed answer."""
    print(f"\n{bold(title)}")
    print(f"  {'endpoint':<15}{'input tokens':>12}{'cached':>9}{'Kong time':>12}")
    results = {}
    for endpoint in ("uncompressed", "compressed"):
        response, kong_ms = ask(endpoint, messages, session_id)
        results[endpoint] = response
        # OpenAI reports input tokens as prompt_tokens, and the cached part of them separately.
        usage = response.usage
        cached = usage.prompt_tokens_details.cached_tokens if usage.prompt_tokens_details else 0
        print(f"  {'/' + endpoint:<15}{usage.prompt_tokens:>12,}{cached:>9,}{kong_ms:>9} ms")

    before = results["uncompressed"].usage.prompt_tokens
    after = results["compressed"].usage.prompt_tokens
    summary = f"Saved on /compressed: {before - after:,} input tokens ({(before - after) / before:.0%} fewer)"
    print(f"  {color('32;1', summary)}")
    answer = " ".join(results["compressed"].choices[0].message.content.split())
    print(f"  Answer from /compressed: {color('2', answer)}")
    return answer


# The get_logs tool result. The tool isn't real: the script generates 200 log records
# with the same six fields. Three of them are errors.
random.seed(7)
logs = []
for i in range(200):
    logs.append({
        "id": i,
        "ts": f"2026-10-18T09:{i % 60:02d}:{i * 7 % 60:02d}Z",
        "service": random.choice(["checkout", "auth", "search", "payments"]),
        "level": "INFO",
        "latency_ms": random.randint(18, 240),
        "msg": "request completed",
    })
logs[37].update(service="payments", level="ERROR", msg="card processor returned 502")
logs[118].update(service="checkout", level="ERROR", msg="upstream timeout after 30000ms")
logs[164].update(service="auth", level="ERROR", msg="connection reset by peer")
tool_result = json.dumps(logs)

# Step 1: the conversation right after the tool ran. The user asks for logs, the
# assistant calls get_logs, the tool result follows, and the user asks about it.
session_id = f"demo-{uuid.uuid4().hex[:8]}"
conversation = [
    {"role": "user", "content": "Pull the last 200 log entries for our services."},
    {"role": "assistant", "content": None, "tool_calls": [{
        "id": "call_1", "type": "function",
        "function": {"name": "get_logs", "arguments": '{"limit": 200}'},
    }]},
    {"role": "tool", "tool_call_id": "call_1", "content": tool_result},
    {"role": "user", "content": "Which log entries are errors? List each id, service, and message."},
]
title = f"Step 1: conversation with a tool result of 200 log records ({len(tool_result):,} characters of JSON)"
answer = run_step(title, conversation, session_id)
errors = ", ".join(f"id {r['id']} {r['service']}" for r in logs if r["level"] == "ERROR")
print(f"  Expected: {errors}")

# Step 2: the next request in the same conversation. The script sends every message
# again, the original JSON included, plus the answer and a new question.
conversation += [
    {"role": "assistant", "content": answer},
    {"role": "user", "content": "What is the latency_ms of entry 150, and which service logged it?"},
]
run_step("Step 2: follow-up question in the same conversation", conversation, session_id)
print(f"  Expected: latency_ms {logs[150]['latency_ms']}, service {logs[150]['service']}")

# Step 3: a new conversation with one short message.
question = [{"role": "user", "content": "In one sentence, what does a tool call return to an agent?"}]
run_step("Step 3: new conversation with one short question", question, f"demo-{uuid.uuid4().hex[:8]}")

# Step 4: the short question with an API key that no AI Consumer has.
bad_key = "not-a-real-key"
print(f"\n{bold('Step 4: request to /compressed with an invalid API key')}")
print(f"  Trying apikey={bad_key!r}")
try:
    ask("compressed", question, f"demo-{uuid.uuid4().hex[:8]}", api_key=bad_key)
    print(f"  {color('31;1', '[ALLOWED]')} Kong accepted the invalid key")
except APIStatusError as e:
    print(f"  {color('31;1', f'[BLOCKED] {e.status_code}')}")
EOF
```
{:.collapsible}

Run it:

```bash
python demo.py
```

Example output:

```text
Step 1: conversation with a tool result of 200 log records (25,540 characters of JSON)
  endpoint       input tokens   cached   Kong time
  /uncompressed        10,272        0        8 ms
  /compressed           5,145        0      112 ms
  Saved on /compressed: 5,127 input tokens (50% fewer)
  Answer from /compressed: Here are the log entries with errors, including their id, service, and message: - id: 37, service: payments, message: card processor returned 502 - id: 118, service: checkout, message: upstream timeout after 30000ms - id: 164, service: auth, message: connection reset by peer Let me know if you need any further details!
  Expected: id 37 payments, id 118 checkout, id 164 auth

Step 2: follow-up question in the same conversation
  endpoint       input tokens   cached   Kong time
  /uncompressed        10,375        0        8 ms
  /compressed           5,248    4,992       24 ms
  Saved on /compressed: 5,127 input tokens (49% fewer)
  Answer from /compressed: The log entry with id 150 has a latency_ms of 146 and was logged by the search service.
  Expected: latency_ms 146, service search

Step 3: new conversation with one short question
  endpoint       input tokens   cached   Kong time
  /uncompressed            21        0        4 ms
  /compressed              21        0       17 ms
  Saved on /compressed: 0 input tokens (0% fewer)
  Answer from /compressed: A tool call returns the tool's output or response data to the agent for further processing or decision-making.

Step 4: request to /compressed with an invalid API key
  Trying apikey='not-a-real-key'
  [BLOCKED] 401
```
{:.no-copy-code}

The `cached` column is the part of the input tokens that OpenAI served from its prompt cache. The `Kong time` column is the time that Kong spent on the request before it called OpenAI, from the `X-Kong-Proxy-Latency` header. If you run the script again, step 1 can also show cached input tokens, because OpenAI keeps cached prompts for up to an hour.

### Check the results

The output confirms the following:

{% table %}
columns:
  - title: Behavior
    key: behavior
  - title: Evidence
    key: evidence
rows:
  - behavior: "Compression of a tool result"
    evidence: "In step 1, OpenAI counted 5,145 input tokens on `/compressed` and 10,272 on `/uncompressed`. Neither request used the prompt cache, so OpenAI billed 50% less input on `/compressed`. The answer still lists the three error records."
  - behavior: "Savings on later turns"
    evidence: "In step 2, `/compressed` has 5,248 input tokens and `/uncompressed` has 10,375, although the script sent the original 200 records again. The answer for entry 150 matches the `Expected` line."
  - behavior: "A stable prompt start with the same session ID"
    evidence: "In step 2, OpenAI served 4,992 of the 5,248 input tokens on `/compressed` from its prompt cache. OpenAI doesn't guarantee a cache hit on either endpoint. In this run, `/uncompressed` got none."
  - behavior: "Short requests pass through"
    evidence: "In step 3, both endpoints have 21 input tokens. The request has nothing that Headroom compresses."
  - behavior: "Time spent on compression"
    evidence: "The first `/compressed` request shows 112 ms of Kong time and `/uncompressed` shows 8 ms. The difference includes the Headroom call. The later `/compressed` requests show 17 to 24 ms."
  - behavior: "Only the compressed endpoint calls Headroom"
    evidence: "In the Headroom terminal, a log line with `path=/v1/compress` appears for each `/compressed` request and for none of the `/uncompressed` requests."
  - behavior: "Authentication before any provider call"
    evidence: "In step 4, Kong returns `401` for the invalid key, and the request never reaches OpenAI."
{% endtable %}

To review the created entities, and per-consumer usage, open the `prompt-compression-with-headroom-and-kong-ai-gateway-recipe` {{site.ai_gateway}} in [{{site.konnect_short_name}}](https://cloud.konghq.com/). For traffic across all your {{site.ai_gateway}}s, use the **Observability** menu.

## How it works

Kong selects the AI Model by path and by the `model` field. On `compressed`, the AI Prompt Compressor Policy sends the conversation to Headroom and replaces the messages with the ones that Headroom returns. Then Kong sends the request to OpenAI with the AI Model Provider's key. On `uncompressed`, Kong sends the original messages.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant A as Agent
    participant K as Kong AI Gateway
    participant H as Headroom
    participant O as OpenAI

    A->>K: POST /compressed/chat/completions (apikey, x-session-id, model compressed)
    activate K
    K->>H: AI Prompt Compressor Policy sends POST /v1/compress (messages, session ID, proxy token)
    activate H
    H-->>K: Compressed messages (else 500 while stop_on_error is true)
    deactivate H
    K->>K: Key Auth AI Auth Strategy accepts the apikey (else 401)
    K->>O: Compressed messages with the OpenAI key
    activate O
    O-->>K: Completion and token usage
    deactivate O
    K-->>A: OpenAI-format response
    deactivate K

    A->>K: POST /uncompressed/chat/completions (apikey, model uncompressed)
    activate K
    K->>K: Key Auth AI Auth Strategy accepts the apikey (else 401)
    K->>O: Original messages with the OpenAI key
    activate O
    O-->>K: Completion and token usage
    deactivate O
    K-->>A: OpenAI-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

In a test on runtime 2.2.0, Kong also sent requests with an invalid or missing key to Headroom, then returned `401` without calling OpenAI.

### Key Auth AI Auth Strategy and AI Consumer

Authentication is an AI Auth Strategy, not an AI Policy. The Key Auth AI Auth Strategy reads the `apikey` header and matches the key against the AI Consumer credentials. On a match, Kong attaches the AI Consumer to the request. The AI Consumer is the identity that rate limits, ACLs, and analytics use. Both AI Models reference this AI Auth Strategy in `access.auth_strategies`, so one key works for both endpoints.

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

### AI Prompt Compressor Policy

The [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy sends the messages of each request to Headroom and forwards the messages that Headroom returns. Headroom decides what to compress. The policy also sends a session ID, so Headroom can recognize the turns that it already compressed for a conversation and return them unchanged.

The following settings configure the AI Prompt Compressor Policy:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`provider: headroom`"
    purpose: "Sends the whole conversation to Headroom. `compression_ranges` and `message_type` apply only to the LLMLingua provider. With `headroom`, they don't change what Kong sends."
  - setting: "`compressor_url`"
    purpose: "The Headroom endpoint, from `HEADROOM_COMPRESSOR_URL`. Kong sends requests to this exact URL, so include the `/v1/compress` path. Without the path, {{site.konnect_short_name}} accepts the configuration, but requests to `/compressed` fail with `500`. By default, Headroom keeps sessions in memory in one process, so point the URL at one instance."
  - setting: "`headroom.proxy_token`"
    purpose: "The Headroom proxy token, from `HEADROOM_PROXY_TOKEN`. It's required when `compressor_url` isn't a loopback address, which includes the quickstart setup. Without it, `kongctl apply` fails with `headroom.proxy_token is required when compressor_url is not a loopback address (localhost, 127.0.0.0/8, ::1)`. The field isn't write-only: the {{site.konnect_short_name}} API returns its value in plain text."
  - setting: "`headroom.session_id_headers` (default)"
    purpose: "The headers that identify a conversation. The default list includes `x-session-id`, which the demo sets to one value for each conversation. Without a session header, the policy builds the session ID from the model, the system message, and the first user message. Each session ID is also scoped to the AI Consumer."
  - setting: "`timeout: 45000`"
    purpose: "The time in milliseconds that the policy waits for Headroom. Keep it higher than the Headroom per-session turn lock (10 seconds) plus the Headroom compression timeout (30 seconds by default). The default, `10000`, is lower than that sum."
  - setting: "`stop_on_error: true`"
    purpose: "When the Headroom call fails, Kong returns `500` with `{\"error\":{\"message\":\"failed to compress prompts: Failure when calling the Headroom compression service\"}}` and doesn't call OpenAI."
  - setting: "`global: false`"
    purpose: "The policy applies only to the AI Models that list it in `policies`."
{% endtable %}

### Headroom compression behavior

Headroom picks a compression method for each message from its content. With Headroom 0.41.0, OpenAI received the following text for message 3 in step 1, 12,021 characters instead of the 25,540 characters of JSON:

```text
"[200]{id:int,latency_ms:int,level:string,msg:string,service:string,ts:string}\n0,56,INFO,request completed,search,2026-10-18T09:00:00Z\n1,184,INFO,request completed,payments,2026-10-18T09:01:07Z\n...
```
{:.no-copy-code}

The script sent the tool result as a JSON string, so Headroom returned the table as a JSON string too: it starts with `"` and separates lines with `\n`. The header line lists each field and its type once, in alphabetical order, and each record follows on its own line. All 200 records are present, including the three errors:

```text
37,189,ERROR,card processor returned 502,payments,2026-10-18T09:37:19Z
118,67,ERROR,upstream timeout after 30000ms,checkout,2026-10-18T09:58:46Z
164,160,ERROR,connection reset by peer,auth,2026-10-18T09:44:08Z
```
{:.no-copy-code}

In tests with Headroom 0.41.0, Headroom also showed the following behavior:

* It didn't change the latest user message or short inputs.
* It didn't compress the outputs of tools with names such as `read_file`, `Read`, `Grep`, `web_fetch`, and `web_search`.
* It reduced a JSON array of nested objects to a subset of its records, with no marker in the text. In a request with 30 nested order records, the model received 15. With the tool listed in `HEADROOM_PROTECT_TOOL_RESULTS`, the model received all 30, and the request was 23% smaller.
* With the same session ID, it returned the earlier turns of a conversation with the same bytes as on the previous turn. This keeps the start of the prompt the same for the OpenAI prompt cache.
* `gpt-4o-mini` misread the log table, with the integer columns `id` and `latency_ms` next to each other, in three of three runs. `gpt-4o` and `gpt-4.1-mini` read it correctly. Check the answers of your model, not only the token counts.

### AI Model Provider and AI Models

The AI Model Provider holds the OpenAI API key and adds it to each request to OpenAI. The two AI Models, `compressed` and `uncompressed`, have their own paths and one target each, which calls the same OpenAI model through the AI Model Provider. Only `compressed` lists the AI Prompt Compressor Policy, so compression is the only difference between the endpoints.

The following settings configure the AI Model Provider and the AI Models:

{% table %}
columns:
  - title: Setting
    key: setting
  - title: Purpose
    key: purpose
rows:
  - setting: "`config.auth` (AI Model Provider)"
    purpose: "The OpenAI API key, from `OPENAI_TOKEN`. Kong adds it to each request to OpenAI. The field is write-only, so {{site.konnect_short_name}} never returns it."
  - setting: "`name`"
    purpose: "`compressed` or `uncompressed`. The AI Models don't set `config.route.model`, so the request's `model` field must be the AI Model name, not the OpenAI model. Another value, including `gpt-4.1-mini`, returns `500` with `failed the initial dns/balancer resolve for 'ai-gateway.upstream.local'`."
  - setting: "`policies`"
    purpose: "`[headroom-compressor]` on `compressed` attaches the AI Prompt Compressor Policy by name. `[]` on `uncompressed` sends requests to OpenAI without a call to Headroom."
  - setting: "`access.auth_strategies`"
    purpose: "Both AI Models require a key from the Key Auth AI Auth Strategy."
  - setting: "`formats: [{type: openai}]` and `capabilities: [generate]`"
    purpose: "The AI Models accept OpenAI-format chat completion requests."
  - setting: "`config.route.paths`"
    purpose: "`/compressed` or `/uncompressed`. The `generate` capability adds `/chat/completions`, so the endpoints are `/compressed/chat/completions` and `/uncompressed/chat/completions`."
  - setting: "`targets[].name`"
    purpose: "The OpenAI model that both AI Models call, from `CHAT_MODEL`."
  - setting: "`config.route.protocols: [http, https]`"
    purpose: "Accepts HTTP, so you can call the local data plane at `http://localhost:8000`."
  - setting: "`config.route.strip_path: true`"
    purpose: "Kong removes `/compressed` or `/uncompressed` from the path before it forwards the request."
  - setting: "`config.max_request_body_size: 10485760`"
    purpose: "Accepts request bodies up to 10 MB, instead of the 8 MB default, for conversations with large tool results."
  - setting: "`config.response_streaming: allow`"
    purpose: "Clients can request streamed responses. Compression applies to the request, so OpenAI bills a streamed request through `/compressed` for the compressed input."
{% endtable %}

{:.info}
> **Production credentials:** This cookbook stores the AI Consumer's API key, the OpenAI API key, and the Headroom proxy token in environment variables for simplicity. In production, use [AI Vaults](/ai-gateway/entities/ai-vault/) to reference them from a secret manager, for example AWS Secrets Manager, HashiCorp Vault, GCP Secret Manager, or Azure Key Vault.

### Response headers

Kong adds the following response headers:

{% table %}
columns:
  - title: Header
    key: header
  - title: Description
    key: description
rows:
  - header: "`X-Kong-LLM-Model`"
    description: "The upstream model that served the request, with the provider name as a prefix, for example `openai/gpt-4.1-mini`."
  - header: "`X-Kong-Proxy-Latency`"
    description: "Time in milliseconds that Kong spent processing the request, excluding the OpenAI call. On `/compressed`, it includes the Headroom call."
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
  - variation: "Keep specific tool results exact"
    how: "Set `HEADROOM_PROTECT_TOOL_RESULTS` on Headroom to a comma-separated list of tool names, for example `list_orders`. Headroom then never removes data from the output of those tools. See the [Headroom proxy reference](https://docs.headroomlabs.ai/docs/proxy)."
  - variation: "Forward requests when Headroom fails"
    how: "Set `stop_on_error: false` on the AI Prompt Compressor Policy. Kong then logs the failure and forwards the original messages, and OpenAI bills the uncompressed input."
  - variation: "Apply the policy to every AI Model"
    how: "Set `global: true` on the AI Prompt Compressor Policy. With `stop_on_error: true`, a Headroom outage then fails every request through the {{site.ai_gateway}}."
  - variation: "Choose the session headers"
    how: "Set `headroom.session_id_headers` to the headers that your agents send for each conversation. Use headers whose values stay the same across turns. See [Headroom prompt flow](/ai-gateway/policies/ai-prompt-compressor/#headroom-prompt-flow)."
  - variation: "Run several Headroom instances"
    how: "Set `HEADROOM_COMPRESS_SESSION_STORE` to a Redis URL on each instance, so the instances share sessions behind a load balancer. This needs Headroom 0.42.0 or later with the `redis` extra. See the [AI Prompt Compressor limitations](/ai-gateway/policies/ai-prompt-compressor/#limitations)."
  - variation: "Track cost per AI Model"
    how: "Set `input_cost` and `output_cost` on each target. See [Model cost management](/ai-gateway/model-cost-management/)."
  - variation: "Compress prose prompts with LLMLingua"
    how: "Set `provider: kong` and point `compressor_url` at Kong's LLMLingua compressor service. See the [LLM cost optimization cookbook](/cookbooks/llm-cost-optimization/) for an example."
  - variation: "Run Headroom in Kubernetes"
    how: "Deploy Headroom next to the data plane with {{site.operator_product_name}}. See [Compress agent traffic with Headroom using {{site.operator_product_name}}](/operator/konnect/how-to/ai-gateway-headroom/)."
  - variation: "Authenticate users with an identity provider"
    how: "Replace the Key Auth AI Auth Strategy with an [OpenID Connect AI Auth Strategy](/ai-gateway/openid-connect/) and map JWT claims to AI Consumers. The AI Models, AI Model Provider, and AI Prompt Compressor Policy don't change. See the [Claude Code SSO cookbook](/cookbooks/claude-code-sso/) for an example with Okta."
{% endtable %}

## Cleanup

The quickstart created an {{site.ai_gateway}} for this recipe only, so this teardown removes only this recipe's configuration. Tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}:

```bash
export KONNECT_CONTROL_PLANE_NAME='prompt-compression-with-headroom-and-kong-ai-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

If you started Headroom for this recipe, stop it with `Ctrl+C` in its terminal and close that terminal. Then, in your first terminal, leave the virtual environment and remove the files and environment variables that the recipe created:

```bash
deactivate
rm -rf .venv .venv-headroom demo.py
unset CONSUMER_API_KEY CHAT_MODEL HEADROOM_PROXY_TOKEN HEADROOM_COMPRESSOR_URL
```

If you created the OpenAI API key only for this recipe, delete it in the [OpenAI dashboard](https://platform.openai.com/api-keys).
