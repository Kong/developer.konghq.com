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
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.15'
  ai-gateway: '2.2'
categories:
  - cost-optimization
featured: true
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - ai-prompt-compressor
  - ai-model-provider
  - ai-model
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key, a Headroom 0.37.0 or later instance that your data plane can reach, and Python 3.11+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. The {{site.ai_gateway}} [quickstart script](https://get.konghq.com/ai) provisions an {{site.ai_gateway}} for this recipe and a local data plane.

        1. Open the [{{site.konnect_short_name}} PAT page](https://cloud.konghq.com/global/account/tokens) and select **Generate token** to create a personal access token.
        1. Export your token:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the {{site.ai_gateway}} name for this recipe and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='prompt-compression-with-headroom-and-kong-ai-gateway-recipe'
           curl -Ls https://get.konghq.com/ai | bash -s -- -k $KONNECT_TOKEN
           ```

           The script creates an {{site.ai_gateway}} named `prompt-compression-with-headroom-and-kong-ai-gateway-recipe` in {{site.konnect_short_name}}, and starts a local data plane in Docker that listens on port `8000`. At the end, the script prints `export` lines like the following, with your own `AI_GATEWAY_ID`:

           ```text
           export KONNECT_TOKEN=$KONNECT_TOKEN
           export KONNECT_CONTROL_PLANE_NAME=prompt-compression-with-headroom-and-kong-ai-gateway-recipe
           export KONNECT_CONTROL_PLANE_URL=https://us.api.konghq.com
           export KONNECT_PROXY_URL='http://localhost:8000'
           export AI_GATEWAY_ID="YOUR_AI_GATEWAY_ID"
           ```
           {:.no-copy-code}

        1. Run the `export` lines that the script printed. Later steps use `AI_GATEWAY_ID`, `KONNECT_PROXY_URL`, and `KONNECT_CONTROL_PLANE_URL`.
    - title: kongctl
      content: |
        This tutorial uses [kongctl](/kongctl/) to manage {{site.ai_gateway}} configuration.

        1. Install [kongctl](/kongctl/).
        1. Print the installed version to make sure it's installed:

           ```bash
           kongctl version
           ```
    - title: OpenAI
      icon_url: /assets/icons/openai.svg
      content: |
        This tutorial uses OpenAI as the LLM provider:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Export the API key as an environment variable. Make sure the value includes the `Bearer` prefix:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Headroom
      content: |
        This tutorial uses [Headroom](https://github.com/headroomlabs-ai/headroom) 0.37.0 or later as the compression service. You can run Headroom as a local installation or use Headroom Enterprise. In both cases, the data plane must be able to connect to Headroom. For more information, see the [Headroom installation guide](https://docs.headroomlabs.ai/docs/installation) and the [Headroom compressor service](/ai-gateway/policies/ai-prompt-compressor/#headroom-compressor-service) section of the AI Prompt Compressor Policy reference.

        By default, Headroom answers `/v1/compress` requests only from loopback callers and returns `404` to all other callers. `HEADROOM_COMPRESS_ALLOW_REMOTE=1` lets the data plane call Headroom. `HEADROOM_PROXY_TOKEN` sets the token that callers must send.

        1. Export your Headroom proxy token. Kong sends this token to Headroom on every call. If you start Headroom in the next steps, you can use any value:

           ```sh
           export HEADROOM_PROXY_TOKEN='YOUR_HEADROOM_PROXY_TOKEN'
           ```

        1. If you don't have a Headroom instance, open a second terminal on the machine that runs the quickstart. Export the same `HEADROOM_PROXY_TOKEN` in that terminal. Then install Headroom in a virtual environment. Headroom requires Python 3.10 or later:

           ```bash
           python3 -m venv .venv-headroom
           source .venv-headroom/bin/activate
           pip install 'headroom-ai[proxy]'
           ```

        1. In the second terminal, start Headroom on port `8787`. Headroom runs in this terminal and prints a log line for each request. Keep the terminal open:

           ```bash
           HEADROOM_COMPRESS_ALLOW_REMOTE=1 headroom proxy --port 8787
           ```

        1. In your first terminal, make sure that Headroom is running:

           ```bash
           curl http://localhost:8787/livez
           ```

           The response contains `"status":"healthy"`:

           ```text
           {"service":"headroom-proxy","status":"healthy","alive":true,"version":"0.41.0","timestamp":"2026-10-21T00:47:39.832326Z","uptime_seconds":553.888,"loop_health":{"status":"healthy","known_failures":0,"last_known_failure":null}}
           ```
           {:.no-copy-code}

        1. Export the URL that the data plane uses to connect to the Headroom `/v1/compress` endpoint. Include the `/v1/compress` path. The quickstart data plane runs in Docker. On Docker Desktop, the data plane connects to a Headroom instance on the same machine at `host.docker.internal`:

           ```sh
           export HEADROOM_COMPRESSOR_URL='http://host.docker.internal:8787/v1/compress'
           ```

           If Headroom runs on a remote host, use the address of that host with the same path, for example `https://headroom.example.com/v1/compress`.
    - title: Python 3.11+
      icon_url: /assets/icons/python.svg
      content: |
        The demo script requires Python 3.11 or later. Create a virtual environment and install the OpenAI SDK:

        ```bash
        python3 -m venv .venv
        source .venv/bin/activate
        pip install 'openai>=1.51.0'
        ```

overview: |
  Agent requests often include large tool results, such as JSON records, logs, and search
  output. The agent sends these tool results again on every later turn of the conversation.
  This recipe sets up two endpoints on {{site.ai_gateway_name}} that call the same OpenAI
  model:

  - `/compressed` sends the messages of each request to
    [Headroom](https://github.com/headroomlabs-ai/headroom) through the [AI Prompt
    Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy. Then it forwards the
    compressed messages to OpenAI.
  - `/uncompressed` forwards each request to OpenAI unchanged.

  Send the same request to both endpoints and compare the number of input tokens that OpenAI
  counts for each endpoint.
---

## The problem

An agent runs a tool when the model returns a tool call, a request for data. A tool is a function in the agent's own code, such as a log query or a database lookup. The agent adds each tool result, the output of the tool, to the conversation that it sends to the model. Tool results are often large structured data, and they cause the following problems:

- **Tool results make prompts large.** A tool call that returns 200 log records adds about 10,000 tokens to the request.
- **The agent sends tool results again on every turn.** Chat completion APIs don't store the conversation, so each request contains the full history, including earlier tool results. The provider charges for those tokens on every request.
- **JSON repeats its field names.** Every record repeats every key. So field names and punctuation make up a large part of the payload.
- **Compression in each agent adds work.** Every agent, in every language and framework, needs its own compression library and configuration.
- **Compression can cancel the prompt cache discount.** OpenAI charges less for the start of a prompt when it's identical to the start of a recent request. For more information, see [OpenAI prompt caching](https://developers.openai.com/api/docs/guides/prompt-caching). If compression rewrites earlier messages differently on each turn, the start of the prompt changes. Then the discount no longer applies.
- **Compression can remove data.** The compressed content can be missing records or use a different format. The response doesn't show what the model received.

Compression must run in one component that handles every request, and keep earlier turns the same from one request to the next. You also need a way to compare a compressed request with an uncompressed request.

## The solution

{{site.ai_gateway_name}} runs compression on the data plane with the AI Prompt Compressor Policy. When the compression `provider` is `headroom`, the Policy sends the messages of each request to Headroom. Then the Policy forwards the messages that Headroom returns to the LLM provider. Headroom controls how much it compresses each message.

This recipe creates two [AI Models](/ai-gateway/entities/ai-model/) that call the same OpenAI model:

- `compressed`, on the `/compressed` path, with the Policy attached
- `uncompressed`, on the `/uncompressed` path, without the Policy

The Policy applies only to the AI Model that lists it. Kong sends requests to `/uncompressed` to OpenAI without a call to Headroom.

Headroom keeps a session for each conversation. When the next turn of a conversation has the same session ID, Headroom reuses the compressed version of the earlier turns. Headroom compresses only the new messages, so the start of the prompt stays the same from turn to turn.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant A as Agent
    participant K as {{site.ai_gateway_name}}
    participant H as Headroom
    participant O as OpenAI

    A->>K: POST /compressed/chat/completions (model compressed)
    activate K
    K->>H: AI Prompt Compressor - POST /v1/compress (messages, session ID, proxy token)
    H-->>K: compressed messages (else 500 while stop_on_error is true)
    K->>O: POST /v1/chat/completions (compressed messages, OpenAI key)
    O-->>K: completion and token usage
    K-->>A: OpenAI-format response
    deactivate K

    A->>K: POST /uncompressed/chat/completions (model uncompressed)
    activate K
    K->>O: POST /v1/chat/completions (original messages, OpenAI key)
    O-->>K: completion and token usage
    K-->>A: OpenAI-format response
    deactivate K
{% endmermaid %}
<!-- vale on -->

{% table %}
columns:
  - title: Component
    key: component
  - title: Responsibility
    key: responsibility
rows:
  - component: "AI Model `compressed`"
    responsibility: Serves `/compressed/chat/completions` and runs the AI Prompt Compressor Policy before calling OpenAI.
  - component: "AI Model `uncompressed`"
    responsibility: Serves `/uncompressed/chat/completions` without the Policy.
  - component: AI Prompt Compressor Policy
    responsibility: Sends the request's messages to Headroom and replaces them with the compressed messages.
  - component: Headroom
    responsibility: Compresses tool results and keeps a session for each conversation.
  - component: AI Model Provider
    responsibility: Stores the OpenAI API key and adds it to every request to OpenAI.
{% endtable %}

## How it works

1. The agent sends a chat request to `/compressed/chat/completions` or `/uncompressed/chat/completions`. The `model` field in the request body is the name of the AI Model on that path: `compressed` or `uncompressed`.
2. Kong selects the AI Model by path and by the `model` value. If the `model` value doesn't match, Kong returns `500` with `failed the initial dns/balancer resolve for 'ai-gateway.upstream.local'`.
3. On `compressed`, the AI Prompt Compressor Policy sends the conversation, the proxy token, and the session ID from the `x-session-id` header to Headroom. Then the Policy replaces the messages in the request with the messages that Headroom returns.
4. The AI Model Provider adds the OpenAI API key, and Kong sends the request to OpenAI. On `uncompressed`, Kong sends the request to OpenAI unchanged.
5. OpenAI returns `usage.prompt_tokens`, the number of input tokens that OpenAI billed for the request. Compare the values from the two endpoints to see the effect of compression.
6. On the next turn with the same `x-session-id`, Headroom reuses the compressed earlier turns and compresses only the new messages.

### AI Prompt Compressor: Headroom connection

The [AI Prompt Compressor](/ai-gateway/policies/ai-prompt-compressor/) Policy sends the messages of a request to a compression service and forwards the messages that the service returns. When `provider` is `headroom`, the compression service is Headroom. By default, the Policy fails closed: if the Headroom call fails, Kong returns `500` and doesn't send the request to OpenAI.

#### Configuration details

The following configuration shows the AI Prompt Compressor Policy settings that this recipe uses. You don't run anything in this section. [Apply the Kong configuration](#apply-the-kong-configuration) creates every resource in one step.

```yaml
ai_gateway_policies:
- name: headroom-compressor
  type: ai-prompt-compressor
  global: false
  config:
    provider: headroom
    compressor_url: http://host.docker.internal:8787/v1/compress
    timeout: 45000
    stop_on_error: true
    headroom:
      proxy_token: YOUR_HEADROOM_PROXY_TOKEN
```
{:.no-copy-code}

- **`provider`**: selects Headroom as the compression service.
- **`compressor_url`**: the URL that the data plane uses to connect to the Headroom `/v1/compress` endpoint. Kong sends requests to this exact URL, so include the `/v1/compress` path. If the path is missing, Kong doesn't call the Headroom compression endpoint, and requests to `/compressed` fail with `500`. Set the URL to a single Headroom instance. Headroom keeps sessions in memory in a single process, so Kong must send all turns of a conversation to the same instance.
- **`headroom.proxy_token`**: your Headroom proxy token. The token is required when `compressor_url` isn't a loopback address. If the token is missing, `kongctl apply` fails with `headroom.proxy_token is required when compressor_url is not a loopback address (localhost, 127.0.0.0/8, ::1)`. In production, store the token in a [Vault](/gateway/secrets-management/) and reference the Vault secret instead of a plain value.
- **`timeout: 45000`**: the time in milliseconds that the Policy waits for Headroom. The Policy reference says to keep this value higher than the Headroom turn-lock and compression timeouts. The Headroom example in the Policy reference uses `45000`, and the default is `10000`.
- **`stop_on_error: true`**: if the Headroom call fails, Kong returns `500` with `{"error":{"message":"failed to compress prompts: Failure when calling the Headroom compression service"}}`. When `stop_on_error` is `false`, Kong logs the failure and forwards the original messages instead.
- **`global: false`**: the Policy applies only to the AI Models that list it in `policies`.

By default, the Policy reads the session ID from the following request headers: `x-claude-code-session-id`, `x-claude-code-agent-id`, `thread-id`, `session-id`, and `x-session-id`. If a request has no session ID, clients that start with the same prompt share one session state. `compression_ranges` and `message_type` configure the LLMLingua provider. These settings don't change what Kong sends to Headroom.

### Headroom: compression behavior

Headroom applies a compression method to each message based on the message content. With Headroom 0.41.0, the requests in this recipe produce the following results:

- A JSON array of records with the same fields becomes a table with one header line and one line per record. Headroom keeps all records and values. In the demo, OpenAI counts 10,272 input tokens for the original request and 5,145 for the compressed request. For the text before and after compression, see [What happened](#what-happened).
- Headroom doesn't change the latest user message or short inputs.
- Headroom doesn't compress the outputs of tools named for file reads and web requests, such as `read_file`, `Read`, `Grep`, `web_fetch`, and `web_search`.
- Headroom can reduce a JSON array of nested objects to a subset of its records, and it adds no marker to the text. For example, in a request with 30 nested order records, the model received 15 records. When the tool was listed in the Headroom `HEADROOM_PROTECT_TOOL_RESULTS` setting, the model received all 30 records, and the request was 23% smaller. For more information, see the [Headroom proxy reference](https://docs.headroomlabs.ai/docs/proxy).

### AI Models: two endpoints

Each AI Model has its own path and calls the same OpenAI model. `compressed` lists the Policy in `policies` and `uncompressed` doesn't, so compression is the only difference between the two endpoints. The `model` field of a request must match the name of the AI Model on that path.

#### Configuration details

The following example shows the `compressed` AI Model. The `uncompressed` AI Model is the same except for its name, its path, and `policies: []`. You apply both AI Models in [Apply the Kong configuration](#apply-the-kong-configuration).

```yaml
ai_gateway_models:
- name: compressed
  type: model
  formats:
  - type: openai
  capabilities:
  - generate
  policies:
  - headroom-compressor
  config:
    max_request_body_size: 10485760
    response_streaming: allow
    route:
      paths:
      - /compressed
  targets:
  - name: gpt-4.1-mini
    provider: headroom-provider
    config:
      type: openai
```
{:.no-copy-code}

- **`name: compressed`**: the name of the AI Model. Clients send this value in the `model` field.
- **`route.paths: [/compressed]`**: the base path. The `generate` capability adds `/chat/completions`, so the endpoint is `/compressed/chat/completions`.
- **`policies: [headroom-compressor]`**: attaches the AI Prompt Compressor Policy by name.
- **`targets[].name`**: the OpenAI model that both AI Models call. You set this value with `CHAT_MODEL` when you apply the configuration.
- **`max_request_body_size: 10485760`**: allows request bodies up to 10 MB, for conversations that contain large tool results. The default is 8 MB.
- **`response_streaming: allow`**: permits streamed responses. Compression applies to the request, so OpenAI bills a streamed request through `/compressed` for the compressed input.

{:.info}
> The two AI Models don't require an API key. Anyone who can connect to port `8000` on the machine that runs the data plane can call the AI Models. To require a key, see [Variations and next steps](#variations-and-next-steps).

### AI Model Provider: OpenAI credential

The [AI Model Provider](/ai-gateway/entities/ai-model-provider/) holds the OpenAI API key and adds the key to every request that Kong sends to OpenAI. Clients don't need the key.

#### Configuration details

The following example shows the AI Model Provider configuration:

```yaml
ai_gateway_model_providers:
- name: headroom-provider
  type: openai
  config:
    auth:
      type: basic
      headers:
      - name: Authorization
        value: Bearer YOUR_OPENAI_API_KEY
```
{:.no-copy-code}

- **`config.auth`**: the header that Kong adds to every request to OpenAI. The key is write-only: {{site.konnect_short_name}} stores the key and never returns it.

{:.info}
> In production, store credentials in [Kong Vaults](/gateway/secrets-management/) instead of environment variables. Kong supports HashiCorp Vault, AWS Secrets Manager, GCP Secret Manager, and the {{site.konnect_short_name}} Config Store.

## Apply the Kong configuration

The configuration in this section creates four resources on the {{site.ai_gateway}} that the quickstart script created:

- An AI Model Provider, `headroom-provider`, that holds your OpenAI API key
- An AI Prompt Compressor Policy, `headroom-compressor`, that points to your Headroom instance
- An AI Model, `compressed`, on `/compressed`, with the Policy attached
- An AI Model, `uncompressed`, on `/uncompressed`, without the Policy

First, adopt the {{site.ai_gateway}} into kongctl. The quickstart script created the {{site.ai_gateway}}, so kongctl doesn't manage it yet:

```bash
kongctl adopt ai-gateway "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

The `kongctl adopt` command adds a label to the {{site.ai_gateway}}: `KONGCTL-namespace: prompt-compression-with-headroom-and-kong-ai-gateway-recipe`. This label marks the {{site.ai_gateway}} as managed by kongctl. The command doesn't change any other setting. The command also doesn't log kongctl in or connect kongctl to the data plane. Every kongctl command in this guide authenticates with your personal access token through the `--pat` flag. For more information, see [kongctl adopt](/kongctl/adopt/).

kongctl confirms the adoption. The output shows your {{site.ai_gateway}} ID:

```text
Adopted AI Gateway "prompt-compression-with-headroom-and-kong-ai-gateway-recipe" (YOUR_AI_GATEWAY_ID) into namespace "prompt-compression-with-headroom-and-kong-ai-gateway-recipe"
```
{:.no-copy-code}

If you run the command a second time, kongctl prints an error and makes no changes. The error says that the {{site.ai_gateway}} already has the namespace label. Continue with the next step.

{% navtabs "Providers" %}
{% tab OpenAI %}

Set the OpenAI model that both endpoints call. This recipe uses `gpt-4.1-mini`:

```bash
export CHAT_MODEL='gpt-4.1-mini'
```

The configuration also uses the `AI_GATEWAY_ID`, `DECK_OPENAI_TOKEN`, `HEADROOM_COMPRESSOR_URL`, and `HEADROOM_PROXY_TOKEN` variables that you exported in the prerequisites.

The following command writes the configuration to `kong-recipe.yaml`, applies the configuration, and deletes the file. When you run `kongctl apply`, kongctl reads each `!env` value from the matching environment variable. Then kongctl creates the resources in {{site.konnect_short_name}}. The `!secret` tag marks the OpenAI API key as write-only, so {{site.konnect_short_name}} never returns it.

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
        value: !secret {source: !env 'DECK_OPENAI_TOKEN'}
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

kongctl prints the planned changes and then creates the four resources. The output ends with the following lines:

```text
Executing changes:
[1/4] [namespace: default] Creating ai_gateway_model_provider: headroom-provider... ✓
[2/4] [namespace: default] Creating ai_gateway_policy: headroom-compressor... ✓
[3/4] [namespace: default] Creating ai_gateway_model: compressed... ✓
[4/4] [namespace: default] Creating ai_gateway_model: uncompressed... ✓

Complete.
Executed 4 changes.
```
{:.no-copy-code}

The data plane receives the new configuration from {{site.konnect_short_name}} within a few seconds.

{% endtab %}
{% endnavtabs %}

## Try it out

Send one request to each endpoint to make sure that both endpoints work. Then run the demo script. The demo script sends an agent conversation with a large tool result to both endpoints and compares the input tokens.

### Send a request to each endpoint

Send a short request to `/uncompressed`. The `model` field is the name of the AI Model on that path:

```bash
curl -s -X POST "$KONNECT_PROXY_URL/uncompressed/chat/completions" \
  -H "Content-Type: application/json" \
  --json '{"model":"uncompressed","messages":[{"role":"user","content":"Reply with exactly: pong"}]}'
```

The response is an OpenAI chat completion. The following example shows the main fields of the response:

```json
{
  "model": "gpt-4.1-mini-2025-04-14",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "pong"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 12,
    "completion_tokens": 1,
    "total_tokens": 13
  }
}
```
{:.no-copy-code}

The `model` field in the response shows `gpt-4.1-mini-2025-04-14` instead of `gpt-4.1-mini`. This difference is expected. OpenAI serves `gpt-4.1-mini` from a dated snapshot and returns the name of the snapshot. The OpenAI [model page](https://developers.openai.com/api/docs/models/gpt-4.1-mini) lists `gpt-4.1-mini-2025-04-14` as the default snapshot. To see the model that Kong sent the request to, add `-i` to the `curl` command. The `X-Kong-LLM-Model` response header shows `openai/gpt-4.1-mini`.

Send the same request to `/compressed`. Kong sends this request to Headroom before it sends the request to OpenAI. The `x-session-id` header assigns a Headroom session to the conversation:

```bash
curl -s -X POST "$KONNECT_PROXY_URL/compressed/chat/completions" \
  -H "Content-Type: application/json" \
  -H "x-session-id: readme-example" \
  --json '{"model":"compressed","messages":[{"role":"user","content":"Reply with exactly: pong"}]}'
```

```json
{
  "model": "gpt-4.1-mini-2025-04-14",
  "choices": [
    {
      "index": 0,
      "message": {
        "role": "assistant",
        "content": "pong"
      },
      "finish_reason": "stop"
    }
  ],
  "usage": {
    "prompt_tokens": 12,
    "completion_tokens": 1,
    "total_tokens": 13
  }
}
```
{:.no-copy-code}

Both responses report 12 input tokens in `prompt_tokens`, because a one-line message has nothing to compress. In the terminal where Headroom runs, a log line with `path=/v1/compress` appears for the request to `/compressed`. No log line appears for the request to `/uncompressed`.

If the `model` value doesn't match the AI Model on the path, Kong returns `500`. For example, Kong returns the following error when you send `"model":"gpt-4.1-mini"` to `/compressed`:

```json
{
  "message":"failed the initial dns/balancer resolve for 'ai-gateway.upstream.local' with: dns server error: 2 server failure",
  "request_id":"3b7338565458882c60517341c9a8504f"
}
```
{:.no-copy-code}

### Run the demo

The demo script sends one agent conversation to both endpoints and compares the number of input tokens that OpenAI counts for each request. Input tokens are the tokens of everything that the model reads for a request, which is the whole conversation. OpenAI bills for every input token and reports the count as `usage.prompt_tokens` in each response. Output tokens are the tokens of the model's answer, reported as `usage.completion_tokens`. Headroom compresses only the input.

The demo conversation is the conversation that an agent sends to the model after the agent runs a tool. The agent adds the tool result to the conversation. Then the agent sends the whole conversation with every later request. In this demo, the tool is `get_logs`, and its result is 200 sample log records that the script generates. The conversation contains the following four messages:

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

In step 1, the script sends the four messages to `/uncompressed`. Then the script sends the same four messages to `/compressed`:

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant D as demo.py
    participant K as {{site.ai_gateway_name}}
    participant H as Headroom
    participant O as OpenAI

    D->>K: POST /uncompressed with messages 1 to 4
    K->>O: messages 1 to 4, unchanged
    O-->>K: answer (10,272 input tokens)
    K-->>D: answer

    D->>K: POST /compressed with the same messages 1 to 4
    K->>H: messages 1 to 4
    Note over H: Rewrites the 200 log records in message 3 as a table.<br/>Leaves messages 1, 2, and 4 unchanged.
    H-->>K: messages 1 to 4, with the table in message 3
    K->>O: messages 1 to 4, with the table in message 3
    O-->>K: answer (5,145 input tokens)
    K-->>D: answer
{% endmermaid %}
<!-- vale on -->

Both requests contain the same conversation. On `/compressed`, OpenAI receives the log records as a table, so OpenAI counts about half as many input tokens. Headroom compresses each request before Kong sends the request to OpenAI. The copy of the conversation in the script doesn't change.

Steps 2 and 3 cover two more cases:

- Step 2 asks a follow-up question in the same conversation. Like an agent, the script sends the whole conversation again, including the original 200 log records, the answer from step 1, and the new question. The request has the same `x-session-id` header as step 1. So Headroom reuses the table from step 1 and doesn't compress the records again.
- Step 3 starts a new conversation with one short question and no tool result. Headroom has nothing to compress, so OpenAI counts the same number of input tokens on both endpoints.

The script doesn't need your OpenAI API key, because Kong adds the key from the AI Model Provider. The OpenAI SDK requires an `api_key` value, so the script passes a placeholder.

Save the script as `demo.py`:

```python
"""Compare input tokens with and without Headroom compression on Kong AI Gateway.

The script plays the part of an agent that has used a tool named get_logs.
get_logs isn't a real tool: the script generates 200 log records as its result.

The script sends the same conversation to two endpoints and prints how many input
tokens OpenAI counted for each one. Input tokens are everything the model reads for a
request, the whole conversation; OpenAI reports them as usage.prompt_tokens.

  /uncompressed  forwards the conversation to OpenAI unchanged.
  /compressed    sends the conversation to Headroom first, then forwards Headroom's version.

It runs three steps:

  Step 1  The conversation right after the tool ran: the user's request, the
          assistant's tool call, the tool result (200 log records in JSON), and a
          question about the records.
          Expected: /compressed sends about half the input tokens, and its answer
          lists the three error records.
  Step 2  The next request in the same conversation, with the same session ID.
          Expected: the savings carry over to the next turn, and the answer is correct.
  Step 3  A new conversation with one short question and no tool result.
          Expected: the same input tokens on both endpoints.

Run:
    export PROXY_URL="$KONNECT_PROXY_URL"
    python demo.py
"""

import json
import os
import random
import sys
import uuid

from openai import OpenAI

PROXY_URL = os.getenv("PROXY_URL", "http://localhost:8000")
USE_COLOR = sys.stdout.isatty() and "NO_COLOR" not in os.environ


def bold(text):
    return f"\033[1m{text}\033[0m" if USE_COLOR else text


def ask(endpoint, messages, session_id):
    """Send the messages to /uncompressed or /compressed. Returns the response and Kong's latency."""
    # Kong adds the OpenAI API key from the AI Model Provider, so this api_key is never used.
    client = OpenAI(base_url=f"{PROXY_URL}/{endpoint}", api_key="unused")
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
    print(f"  {bold(summary)}")
    answer = " ".join(results["compressed"].choices[0].message.content.split())
    print(f"  Answer from /compressed: {answer}")
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
```
{:.collapsible}

In the Python virtual environment from the prerequisites, set `PROXY_URL` to the data plane URL and run the script:

```bash
export PROXY_URL="$KONNECT_PROXY_URL"
python demo.py
```

For each step, the script prints one line per endpoint with the following columns:

- `input tokens`: the number of input tokens that OpenAI counted for the request, from `usage.prompt_tokens`.
- `cached`: the number of input tokens that OpenAI served from its [prompt cache](https://developers.openai.com/api/docs/guides/prompt-caching).
- `Kong time`: the time in milliseconds that Kong spent on the request before Kong sent the request to OpenAI. The script reads this value from the `X-Kong-Proxy-Latency` response header. On `/compressed`, this time includes the call to Headroom.

Then the script prints the number of input tokens that `/compressed` saved and the answer from `/compressed`. For steps 1 and 2, the script also prints the correct answer for comparison. The following example shows the output:

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
```
{:.no-copy-code}

### What happened

1. In step 1, OpenAI counted 5,145 input tokens for the `/compressed` request and 10,272 for the `/uncompressed` request. The answer from `/compressed` still listed the three error records. Neither request used the prompt cache, so OpenAI billed 50% less for the input of the `/compressed` request. Headroom changed only message 3, the tool result. The script sent the tool result as JSON, 25,540 characters:

   ```json
   [{"id": 0, "ts": "2026-10-18T09:00:00Z", "service": "search", "level": "INFO", "latency_ms": 56, "msg": "request completed"}, {"id": 1, "ts": "2026-10-18T09:01:07Z", "service": "payments", "level": "INFO", "latency_ms": 184, "msg": "request completed"}, ...
   ```
   {:.no-copy-code}

   OpenAI received the following text instead, 12,021 characters:

   ```text
   "[200]{id:int,latency_ms:int,level:string,msg:string,service:string,ts:string}\n0,56,INFO,request completed,search,2026-10-18T09:00:00Z\n1,184,INFO,request completed,payments,2026-10-18T09:01:07Z\n...
   ```
   {:.no-copy-code}

   Headroom converted the array into a table: a header line with the field names and types, then one line per record, separated by `\n`. Each field name appears once instead of 200 times. All 200 records are present, including the three errors:

   ```text
   37,189,ERROR,card processor returned 502,payments,2026-10-18T09:37:19Z
   118,67,ERROR,upstream timeout after 30000ms,checkout,2026-10-18T09:58:46Z
   164,160,ERROR,connection reset by peer,auth,2026-10-18T09:44:08Z
   ```
   {:.no-copy-code}

1. In step 2, OpenAI counted 5,248 input tokens for the `/compressed` request and 10,375 for the `/uncompressed` request. The answer for entry 150 was correct. The request had the same session ID as step 1, so Headroom reused the table from step 1. As a result, messages 1 to 4 were identical to the messages in the step 1 request to `/compressed`. OpenAI served 4,992 of the 5,248 input tokens from its prompt cache. OpenAI doesn't guarantee a cache hit on either endpoint. In this run, the `/uncompressed` request got no cache hit.
1. In step 3, OpenAI counted 21 input tokens on both endpoints. Headroom doesn't change the latest user message, and the request had nothing else to compress.
1. Kong spent 112 ms on the first `/compressed` request and 8 ms on the `/uncompressed` request. The difference includes the Headroom call. On the other `/compressed` requests, Kong spent 17 to 24 ms.

If you run the script again, step 1 can also show cached input tokens. The second run sends the same conversation as the first run, and OpenAI keeps cached prompts for up to an hour.

### Explore in {{site.konnect_short_name}}

Open [{{site.konnect_short_name}}](https://cloud.konghq.com/) and find the {{site.ai_gateway}} named `prompt-compression-with-headroom-and-kong-ai-gateway-recipe`. The {{site.ai_gateway}} contains the AI Model Provider `headroom-provider`, the AI Prompt Compressor Policy `headroom-compressor`, and the AI Models `compressed` and `uncompressed`.

To list the AI Models with their paths and Policies, send the following request to the {{site.konnect_short_name}} API:

```bash
curl -s "$KONNECT_CONTROL_PLANE_URL/v1/ai-gateways/$AI_GATEWAY_ID/models" \
  -H "Authorization: Bearer $KONNECT_TOKEN" \
  | jq -r '.data[] | "\(.name)  path=\(.config.route.paths[0])  policies=\(.policies)"'
```

```text
uncompressed  path=/uncompressed  policies=[]
compressed  path=/compressed  policies=["headroom-compressor"]
```
{:.no-copy-code}

{{site.ai_gateway_name}} records token consumption and request latency for every AI Model. For traffic analysis across every {{site.ai_gateway}}, go to the [Observability](/observability/) menu in {{site.konnect_short_name}}.

## Variations and next steps

**Require an API key.** Add a key-auth [AI Auth Strategy](/ai-gateway/entities/ai-auth-strategy/) and an [AI Consumer](/ai-gateway/entities/ai-consumer/). Then list the strategy in the `access.auth_strategies` field of each AI Model. The [Mistral AI cookbook](/cookbooks/mistral-ai-with-kong-ai-gateway/) shows the configuration. If the AI Auth Strategy rejects a request to `/compressed`, Kong still sends the request to Headroom. Kong doesn't send the rejected request to OpenAI.

**Keep specific tool results exact.** Set `HEADROOM_PROTECT_TOOL_RESULTS` on Headroom to a comma-separated list of tool names, such as `list_orders`. Headroom doesn't apply lossy compression to the results of those tools.

**Apply the Policy to every AI Model.** Set `global: true` on the Policy. If `stop_on_error` is `true`, a Headroom outage then fails every request through the {{site.ai_gateway}}. To forward the original messages when Kong can't connect to Headroom, set `stop_on_error: false`.

**Track cost per AI Model.** Set `input_cost` and `output_cost` on each target. For more information, see [Model cost management](/ai-gateway/model-cost-management/).

**Run Headroom in Kubernetes.** For instructions, see [Compress agent traffic with Headroom using {{site.operator_product_name}}](/operator/konnect/how-to/ai-gateway-headroom/).

## Cleanup

When you're done, tear down the local data plane and delete the {{site.ai_gateway}} from {{site.konnect_short_name}}. When you delete the {{site.ai_gateway}}, {{site.konnect_short_name}} also deletes the AI Model Provider, the Policy, and both AI Models:

```bash
export KONNECT_CONTROL_PLANE_NAME='prompt-compression-with-headroom-and-kong-ai-gateway-recipe' && curl -Ls https://get.konghq.com/ai | bash -s -- -d -k $KONNECT_TOKEN
```

The script stops and removes the data plane container. Then the script deletes the {{site.ai_gateway}}:

```text
Destroying local Kong AI Gateway Deployment...
⏲︎ Stopping and removing containers and networks: ✔
⏲︎ Deleting Konnect Control Plane 'prompt-compression-with-headroom-and-kong-ai-gateway-recipe': ✔
```
{:.no-copy-code}

Stop Headroom with `Ctrl+C` in the terminal where it runs, if you started it for this recipe. Delete the OpenAI API key in the [OpenAI dashboard](https://platform.openai.com/api-keys) if you created it only for this recipe.
