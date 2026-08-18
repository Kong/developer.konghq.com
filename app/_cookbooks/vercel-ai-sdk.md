---
title: Vercel AI SDK with Kong AI Gateway
description: Route Vercel AI SDK requests through {{site.ai_gateway_name}} with the OpenAI-compatible provider, using Consumer authentication and centrally managed provider credentials.
url: "/cookbooks/vercel-ai-sdk/"
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
  gateway: '3.6'
categories:
  - llm
featured: false
popular: false

# Machine-readable fields for AI agent setup
plugins:
  - key-auth
  - ai-proxy
requires_embeddings: false
providers:
  - openai

hint: "Requires an OpenAI API key and Node.js 22+."
prereqs:
  skip_product: true
  skip_tool: true
  inline:
    - title: "{{site.konnect_product_name}}"
      content: |
        This tutorial uses {{site.konnect_product_name}}. You will provision a recipe-scoped Control Plane and local Data Plane via the [quickstart script](https://get.konghq.com/quickstart).

        1. Create a new personal access token by opening the [Konnect PAT page](https://cloud.konghq.com/global/account/tokens) and selecting **Generate Token**.
        1. Export your token. The same token is reused later for kongctl commands:

           ```bash
           export KONNECT_TOKEN='YOUR_KONNECT_PAT'
           ```

        1. Set the recipe-scoped Control Plane name and run the quickstart script:

           ```bash
           export KONNECT_CONTROL_PLANE_NAME='vercel-ai-sdk-recipe'
           curl -Ls https://get.konghq.com/quickstart | bash -s -- -k $KONNECT_TOKEN --deck-output
           ```

           This provisions a Konnect Control Plane named `vercel-ai-sdk-recipe`, a local Data Plane connected to it, and prints `export` lines for the rest of the session vars. Paste those into your shell when prompted.
    - title: kongctl + decK
      content: |
        This tutorial uses [kongctl](/kongctl/) and [decK](/deck/) to manage Kong configuration.

        1. Install **kongctl** from [developer.konghq.com/kongctl](/kongctl/).
        1. Install **decK** version 1.43 or later from [docs.konghq.com/deck](https://docs.konghq.com/deck/).
        1. Verify both are installed:

           ```bash
           kongctl version
           deck version
           ```
    - title: OpenAI
      icon_url: /assets/icons/openai.svg
      content: |
        This tutorial routes to OpenAI:

        1. [Create an OpenAI account](https://auth.openai.com/create-account).
        1. [Get an API key](https://platform.openai.com/api-keys).
        1. Create a decK variable with the API key. {{site.base_gateway}} injects this credential into every upstream request, so your application code never holds it:

           ```sh
           export DECK_OPENAI_TOKEN='Bearer sk-YOUR-KEY'
           ```
    - title: Node.js 22+
      content: |
        The AI SDK v7 requires Node.js 22 or later. Verify your version and install the SDK packages in a new project:

        ```bash
        node --version   # must be >= 22

        mkdir vercel-ai-gateway && cd vercel-ai-gateway
        npm init -y
        npm pkg set type=module
        npm install ai @ai-sdk/openai-compatible zod
        ```

overview: |
  Point the Vercel AI SDK at {{site.ai_gateway_name}} instead of directly at OpenAI. The SDK's OpenAI-compatible provider takes a `baseURL`, and {{site.ai_gateway_name}} speaks the OpenAI wire format, so `generateText`, `streamText`, tool calling, and structured output all work against the gateway.

  By the end of this recipe you will have a single `/vercel` endpoint that authenticates each request against a Consumer credential, injects the OpenAI provider key server-side, and proxies the call. Your AI SDK code only changes the URL and key it uses.
---

## The problem

A Vercel AI SDK app usually talks straight to a provider: install `@ai-sdk/openai`, put an OpenAI key in an environment variable, and call `generateText` from a server route. That works for one app, but it does not scale across a team or across environments.

- **Provider keys spread across every app and environment.** Every app and every deployment needs the OpenAI key. A leaked key affects everyone, and rotating it means redeploying everything that holds it.
- **No identity at the edge.** With the app calling OpenAI directly, there is nowhere to attribute usage to a team, enforce a per-app quota, or revoke a single app without rotating the shared provider key.
- **Model choice is baked into code.** The upstream model is a string in the code. Swapping it means editing and redeploying.
- **No shared control point.** Rate limits, logging, and cost attribution get reimplemented per app, because there is no layer between the AI SDK and the provider to apply policy once.

## The solution

{{site.ai_gateway_name}} inserts a Service and Route between the AI SDK and OpenAI. The SDK still builds an OpenAI-format request, but sends it to a Kong Route. The Route authenticates the request against a Consumer credential, injects the real OpenAI key from Kong's configuration, and proxies the call. Your application only holds a Kong-issued key, and the model and provider credentials live in one place the platform team controls.

The only change in your AI SDK code is the `baseURL` and `apiKey` you pass to the OpenAI-compatible provider.

<!-- vale off -->
{% mermaid %}
sequenceDiagram
    participant C as AI SDK app
    participant K as {{site.ai_gateway_name}}
    participant O as OpenAI

    C->>K: POST /vercel/chat/completions (Authorization Bearer Kong key)
    activate K
    K->>K: key-auth validates key, attaches Consumer
    K->>K: ai-proxy strips client key, injects OpenAI credential
    K->>O: Forwarded chat completion request
    activate O
    O-->>K: Completion
    deactivate O
    K-->>C: OpenAI-format response
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
  - component: AI SDK app
    responsibility: "Builds OpenAI-format requests with the `@ai-sdk/openai-compatible` provider, pointed at the Kong Route via `baseURL`, authenticating with a Kong-issued key"
  - component: Key Auth Plugin
    responsibility: Validates the key against a registered Consumer credential and attaches the Consumer identity to the request
  - component: AI Proxy Plugin
    responsibility: "Strips the client key, injects the OpenAI provider credential, and proxies the request to OpenAI"
  - component: Kong Consumer
    responsibility: Identity attached to authenticated requests, used for rate limiting, ACLs, and analytics attribution
  - component: OpenAI
    responsibility: Processes the prompt and returns a completion
{% endtable %}

## How it works

A request from the AI SDK is processed in three stages: authentication, credential injection, and proxying.

1. The AI SDK sends a chat completion request (OpenAI format) to `/vercel`. The OpenAI-compatible provider appends the `/chat/completions` path to the `baseURL` you configure.
2. The Key Auth Plugin reads the `Authorization` header and looks the key up in Kong's Consumer credential store. If the key is missing or unknown, Kong returns `401` before any upstream call. On a match, it attaches the matching Consumer.
3. The AI Proxy Plugin strips the client's key, injects the OpenAI credential from its own configuration, and forwards the request to OpenAI. The response is returned in the OpenAI format the SDK expects.

### Use the OpenAI-compatible provider, not the OpenAI provider

The AI SDK ships two relevant packages. Use [`@ai-sdk/openai-compatible`](https://ai-sdk.dev/providers/openai-compatible-providers) (`createOpenAICompatible`) for a self-hosted OpenAI-compatible endpoint like {{site.ai_gateway_name}}. The `@ai-sdk/openai` package targets OpenAI's full Responses API and is meant for OpenAI itself. The OpenAI-compatible provider sends the Chat Completions shape that Kong's `llm/v1/chat` route type expects.

`createOpenAICompatible`'s `apiKey` option is sent as an `Authorization: Bearer <key>` header, which lines up directly with the key-auth configuration below.

### Key Auth: authentication and the Bearer header

The Key Auth Plugin does an exact string match on the header value, so this recipe registers the Consumer credential *with* the `Bearer ` prefix and reads the `Authorization` header. That lets your code pass a plain key (`apiKey: 'my-api-key'`) while Kong matches the full `Bearer my-api-key` string.

#### Configuration details

```yaml
- name: key-auth
  config:
    key_names:
      - Authorization
    hide_credentials: true
```
{:.no-copy-code}

- **`key_names: [Authorization]`**: The header Kong reads the key from, matched exactly including the `Bearer ` prefix.
- **`hide_credentials: true`**: Strips the `Authorization` header before the request continues, so the client key never leaks upstream. The AI Proxy Plugin then sets its own `Authorization` header with the OpenAI credential.

{:.info}
> For production identity, swap key-auth for [OpenID Connect](/plugins/openid-connect/) and map JWT claims to Consumers. Only the auth header your code sends changes. See the [claude-code-sso recipe](/cookbooks/claude-code-sso/) for an end-to-end example with Okta.

### AI Proxy: credential injection and proxying

The [AI Proxy](/plugins/ai-proxy/) Plugin holds the OpenAI credential and the upstream model, and proxies the request. Your app never holds an OpenAI key.

#### Configuration details

{%- raw %}
```yaml
- name: ai-proxy
  config:
    route_type: llm/v1/chat
    auth:
      header_name: Authorization
      header_value: ${{ env "DECK_OPENAI_TOKEN" }}
    model:
      provider: openai
      name: gpt-4o
```
{% endraw -%}
{:.no-copy-code}

- **`route_type: llm/v1/chat`**: Selects the chat-completions path.
- **`auth`**: Kong injects this credential into every upstream request. `DECK_OPENAI_TOKEN` holds the full `Bearer sk-...` value.
- **`model`**: The upstream provider and model. Change `name` and re-apply to swap the model without touching application code.

{:.info}
> **Production credentials.** This recipe stores the Consumer key in Plugin config and the OpenAI key in an environment variable for simplicity. In production, use [Kong Vaults](/gateway/secrets-management/) to reference both from your secret manager instead.

## Apply the Kong configuration

The following configuration creates a {{site.base_gateway}} Service and Route at `/vercel`, attaches [key-auth](/plugins/key-auth/) to identify Consumers via the `Authorization` header, and attaches [ai-proxy](/plugins/ai-proxy/) to inject the OpenAI credential and proxy the request. All resources are scoped with `select_tags` and a kongctl `namespace` so they tear down cleanly.

First, adopt the quickstart Control Plane into a kongctl namespace:

```bash
kongctl adopt control-plane "${KONNECT_CONTROL_PLANE_NAME}" \
  --namespace "${KONNECT_CONTROL_PLANE_NAME}" \
  --pat "${KONNECT_TOKEN}"
```

Apply the configuration:

```bash
{%- raw %}
cat <<'EOF' > kong-recipe.yaml
_format_version: '3.0'
_info:
  select_tags:
  - vercel-ai-sdk-recipe
services:
- name: vercel-ai-sdk
  url: http://localhost
  routes:
  - name: vercel-ai-sdk
    paths:
    - /vercel
    protocols:
    - http
    - https
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: key-auth
    instance_name: vercel-ai-sdk-auth
    config:
      key_names:
      - Authorization
      hide_credentials: true
  - name: ai-proxy
    instance_name: vercel-ai-sdk-proxy
    config:
      route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      model:
        provider: openai
        name: gpt-4o
consumers:
- username: vercel-app
  keyauth_credentials:
  - key: Bearer my-api-key
EOF
{% endraw -%}

echo "
_defaults:
  kongctl:
    namespace: vercel-ai-sdk-recipe
control_planes:
  - ref: recipe-cp
    name: \"${KONNECT_CONTROL_PLANE_NAME}\"
    _deck:
      files:
        - kong-recipe.yaml
" | kongctl apply -f - -o text --auto-approve --pat "${KONNECT_TOKEN}"

rm -f kong-recipe.yaml
```
{: data-test-step="block" .collapsible }

## Try it out

The demo script runs three AI SDK calls against the Route: a basic `generateText`, a streamed `streamText`, and a tool-calling request. It then presents an invalid key to show Kong rejecting the request with `401` before any upstream call.

Create the demo script:

```bash
cat <<'EOF' > demo.mjs
// Vercel AI SDK through Kong AI Gateway.
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';
import { generateText, streamText, tool } from 'ai';
import { z } from 'zod';

const PROXY_URL = process.env.PROXY_URL ?? 'http://localhost:8000';

// baseURL points at the Kong Route. The provider appends /chat/completions.
// apiKey is sent as "Authorization: Bearer my-api-key", which Kong's
// key-auth matches against the registered Consumer credential.
const kong = createOpenAICompatible({
  name: 'kong',
  baseURL: `${PROXY_URL}/vercel`,
  apiKey: 'my-api-key',
});

async function basic() {
  console.log('\n== Basic completion ==');
  const { text } = await generateText({
    model: kong('gpt-4o'),
    prompt: 'What is the capital of France?',
  });
  console.log(text);
}

async function streaming() {
  console.log('\n== Streaming ==');
  const result = streamText({
    model: kong('gpt-4o'),
    prompt: 'Write a one-sentence haiku about gateways.',
  });
  for await (const chunk of result.textStream) process.stdout.write(chunk);
  console.log();
}

async function toolCalling() {
  console.log('\n== Tool calling ==');
  const getWeather = tool({
    description: 'Get the current weather for a location',
    inputSchema: z.object({ location: z.string() }),
    execute: async ({ location }) => ({ location, conditions: 'Sunny, 72F' }),
  });
  const result = await generateText({
    model: kong('gpt-4o'),
    tools: { getWeather },
    prompt: "What's the weather in NYC?",
  });
  console.log('tool calls:', result.toolCalls);
}

async function rejected() {
  console.log('\n== Invalid key (Kong rejects before reaching OpenAI) ==');
  const bad = createOpenAICompatible({
    name: 'kong',
    baseURL: `${PROXY_URL}/vercel`,
    apiKey: 'not-a-real-key',
  });
  try {
    await generateText({ model: bad('gpt-4o'), prompt: 'This should never reach OpenAI.' });
  } catch (e) {
    console.log('blocked:', e.message);
  }
}

await basic();
await streaming();
await toolCalling();
await rejected();
EOF
```
{:.collapsible}

Run it:

```bash
node demo.mjs
```

The response should look like this:

```text
== Basic completion ==
The capital of France is Paris.

== Streaming ==
Gates open, tokens flow, requests find their path home.

== Tool calling ==
tool calls: [ { toolCallId: 'call_...', toolName: 'getWeather', input: { location: 'NYC' } } ]

== Invalid key (Kong rejects before reaching OpenAI) ==
blocked: ... 401 ... No credentials found for given apikey
```
{:.no-copy-code}

### What happened

1. **The AI SDK talked to Kong, not OpenAI.** Setting `baseURL` on the OpenAI-compatible provider is the only change from a direct OpenAI integration. The provider appended `/chat/completions` and sent an ordinary OpenAI-format request.
2. **generateText, streamText, and tools work unchanged.** The SDK functions behave exactly as they do against OpenAI. Whether tool calling succeeds depends on the upstream model, the same as calling that model directly.
3. **Kong enforced auth before any upstream call.** The invalid-key request was rejected by key-auth in a few milliseconds. OpenAI was never contacted and no provider quota was consumed.
4. **The OpenAI key never left Kong.** The app only ever held the Kong-issued key `my-api-key`. The `Bearer sk-...` provider credential lived in `DECK_OPENAI_TOKEN` on the Kong side and was injected by the AI Proxy Plugin.

### Explore in Konnect

Open [Konnect](https://cloud.konghq.com/) and navigate to **API Gateway** → **Gateways** → **vercel-ai-sdk-recipe**:

- **Gateway services** → **vercel-ai-sdk**: the Service, with tabs for Configuration, Routes, Plugins, and Analytics.
  - **Plugins** tab: the `vercel-ai-sdk-auth` (key-auth) and `vercel-ai-sdk-proxy` (ai-proxy) instances.
- **Consumers** → **vercel-app**: the Consumer the key maps to.

The **Analytics** tab shows request counts, error rates, latency, and token usage for traffic through this recipe.

## Variations and next steps

**Structured output.** `generateText` and `streamText` accept an `output` option for schema-validated objects (the current pattern; `generateObject` is deprecated as of AI SDK 6):

```js
import { generateText, Output } from 'ai';
import { z } from 'zod';

const { output } = await generateText({
  model: kong('gpt-4o'),
  output: Output.object({
    schema: z.object({
      summary: z.string(),
      riskLevel: z.enum(['low', 'medium', 'high']),
    }),
  }),
  prompt: 'Assess the risk of this API usage spike.',
});
```

**Next.js server route.** In a Next.js app, construct the provider in a server route so the key stays server-side, and let the client talk only to that route. Never construct the provider in a `'use client'` component or expose the Kong key as a `NEXT_PUBLIC_*` variable, since those are inlined into the browser bundle:

```js
// app/api/chat/route.ts
import { streamText, convertToModelMessages, createUIMessageStreamResponse, toUIMessageStream } from 'ai';
import { createOpenAICompatible } from '@ai-sdk/openai-compatible';

const kong = createOpenAICompatible({
  name: 'kong',
  baseURL: process.env.KONG_AI_GATEWAY_URL, // e.g. https://your-gateway.example.com/vercel
  apiKey: process.env.KONG_AI_GATEWAY_KEY,
});

export async function POST(req) {
  const { messages } = await req.json();
  const result = streamText({ model: kong('gpt-4o'), messages: await convertToModelMessages(messages) });
  return createUIMessageStreamResponse({ stream: toUIMessageStream({ stream: result.stream }) });
}
```

**Reaching the gateway from a deployment.** `http://localhost:8000` is only reachable from your own machine. When this app is deployed (for example to Vercel), the server code runs in the cloud and cannot reach a local gateway. Point `baseURL` at a gateway URL reachable from where the code runs, and read it from an environment variable so switching environments is a config change, not a code change.

**Embeddings.** The SDK's `embeddingModel` uses a different route type (`llm/v1/embeddings`, available in {{site.base_gateway}} 3.11+). Add a second Route and AI Proxy instance for embeddings. The `genai_category: text/embeddings` setting is required so the plugin treats the route as embeddings rather than chat:

{%- raw %}
```yaml
- name: vercel-ai-sdk-embeddings
  paths:
  - /vercel-embeddings
  plugins:
  - name: ai-proxy
    config:
      genai_category: text/embeddings
      route_type: llm/v1/embeddings
      auth:
        header_name: Authorization
        header_value: ${{ env "DECK_OPENAI_TOKEN" }}
      model:
        provider: openai
        name: text-embedding-3-small
```
{% endraw -%}
{:.no-copy-code}

```js
import { embed } from 'ai';

const embeddingProvider = createOpenAICompatible({
  name: 'kong',
  baseURL: `${PROXY_URL}/vercel-embeddings`,
  apiKey: 'my-api-key',
});

const { embedding } = await embed({
  model: embeddingProvider.embeddingModel('text-embedding-3-small'),
  value: 'sunny day at the beach',
});
```

**Add per-Consumer rate limits.** With key-auth mapping requests to Consumers, attach [ai-rate-limiting-advanced](/plugins/ai-rate-limiting-advanced/) to apply token quotas per Consumer. See the [llm-cost-optimization recipe](/cookbooks/llm-cost-optimization/).

**Route across providers or models.** To pick between models per request, swap [ai-proxy](/plugins/ai-proxy/) for [ai-proxy-advanced](/plugins/ai-proxy-advanced/) and configure targets with `model_alias`. See the [basic-llm-routing recipe](/cookbooks/basic-llm-routing/).

## Cleanup

The recipe scoped all resources with `select_tags` and a kongctl `namespace`, so this teardown removes only this recipe's configuration:

```bash
export KONNECT_CONTROL_PLANE_NAME='vercel-ai-sdk-recipe' && curl -Ls https://get.konghq.com/quickstart | bash -s -- -d -k $KONNECT_TOKEN
```
