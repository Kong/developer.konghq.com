---
title: Vercel AI SDK
description: Use Vercel AI SDK with {{site.ai_gateway_name}} to centralize model routing, provider credentials, authentication, and AI traffic controls.
url: "/ai-integrations/vercel-ai-sdk/"
content_type: ai_integration
layout: ai_integration
products:
  - ai-gateway
tools:
  - deck
canonical: true
works_on:
  - konnect
min_version:
  gateway: '3.14'
categories:
  - libraries
  - frameworks
featured: true

overview: |
  [Vercel AI SDK](https://ai-sdk.dev/) is a TypeScript toolkit for building AI applications with a
  single, provider-agnostic API for text generation, streaming, structured outputs, tools, and agents.
  Because its OpenAI provider can call any OpenAI-compatible endpoint, you can point it at a
  {{site.ai_gateway_name}} Route instead of calling a provider directly.

  Your application code stays focused on `generateText`, `streamText`, `generateObject`, tools, and
  agents, while the gateway owns the parts you do not want in the client: provider credentials, model
  selection, authentication, observability, guardrails, rate limiting, and semantic caching. You add or
  change those controls at the gateway without touching application code.
---

## Quick start

Point Vercel AI SDK's OpenAI provider at a {{site.ai_gateway_name}} Route running on Kong Konnect, then
use the SDK exactly as you normally would.

### Prerequisites

- Node.js and a project with Vercel AI SDK installed.
- A [Kong Konnect](https://konnect.konghq.com) account with a Gateway control plane and a running data
  plane. New to AI Gateway? Start with [Get started with AI Gateway](/ai-gateway/get-started/).
- A Route on that control plane with the [AI Proxy](/plugins/ai-proxy/) or
  [AI Proxy Advanced](/plugins/ai-proxy-advanced/) Plugin, plus an upstream provider key held by the
  Plugin. If you do not have one yet, see [Set up the Kong AI Gateway Route](#set-up-the-kong-ai-gateway-route).
- A Kong Konnect Personal Access Token (`kpat_...`) to configure the gateway with decK.

### Install

```bash
npm install ai @ai-sdk/openai zod
```

### Configure the provider

Create the OpenAI provider with `createOpenAI`, but set `baseURL` to your {{site.ai_gateway_name}}
Route instead of the OpenAI API:

```ts
import { createOpenAI } from '@ai-sdk/openai';

export const kong = createOpenAI({
  // Your Kong Konnect AI Gateway proxy URL plus the Route path, not the OpenAI API.
  baseURL: `${process.env.KONNECT_AI_GATEWAY_URL}/vercel-ai-sdk`,
  // The upstream provider key lives in the gateway, so this value is not used.
  apiKey: 'kong',
});
```

Set `KONNECT_AI_GATEWAY_URL` to your Konnect Gateway's proxy URL, the data plane endpoint that serves
your Routes:

```bash
KONNECT_AI_GATEWAY_URL='https://your-gateway-host'
```

Kong receives the request, injects the real provider credential, selects the upstream model, and
returns an OpenAI-compatible response to the SDK.

{:.info}
> Vercel AI SDK 5 and later call the OpenAI Responses API by default when you use `kong('model')`.
> The examples on this page use `kong.chat('model')` so the SDK sends chat-completion requests that
> match the `llm/v1/chat` route type in Kong. To use the Responses API instead, see
> [Use the Responses API](#use-the-responses-api).

### Generate text

```ts
import { generateText } from 'ai';
import { kong } from './kong-ai-gateway';

const { text, usage } = await generateText({
  model: kong.chat('gpt-4o'),
  prompt: 'Write a concise release note for a new AI Gateway model routing policy.',
});

console.log(text);
console.log(usage);
```

That is the whole integration. Every other Vercel AI SDK feature works the same way, because the SDK is
still speaking OpenAI's chat-completion protocol to Kong.

## Stream text

Stream tokens as they are generated with `streamText`:

```ts
import { streamText } from 'ai';
import { kong } from './kong-ai-gateway';

const result = streamText({
  model: kong.chat('gpt-4o'),
  prompt: 'Stream a short checklist for safely launching an AI feature.',
});

for await (const delta of result.textStream) {
  process.stdout.write(delta);
}
```

In a Next.js Route Handler, return the stream directly to the browser:

```ts
import { streamText } from 'ai';
import { kong } from '@/lib/kong-ai-gateway';

export async function POST(req: Request) {
  const { messages } = await req.json();

  const result = streamText({
    model: kong.chat('gpt-4o'),
    messages,
  });

  return result.toTextStreamResponse();
}
```

## Generate structured data

Use `generateObject` with a Zod schema to get validated, typed output. Kong stays on the request path
while the SDK enforces the schema:

```ts
import { generateObject } from 'ai';
import { z } from 'zod';
import { kong } from './kong-ai-gateway';

const { object } = await generateObject({
  model: kong.chat('gpt-4o'),
  schema: z.object({
    title: z.string(),
    risks: z.array(z.string()),
    rolloutSteps: z.array(z.string()),
  }),
  prompt: 'Create a launch plan for adding semantic caching to an AI product.',
});

console.log(object);
```

## Use tools

Tool calling works through Kong whenever the upstream model supports it:

```ts
import { generateText, tool } from 'ai';
import { z } from 'zod';
import { kong } from './kong-ai-gateway';

const result = await generateText({
  model: kong.chat('gpt-4o'),
  tools: {
    getGatewayPolicy: tool({
      description: 'Return the policy status for an AI Gateway route.',
      inputSchema: z.object({
        routeName: z.string().describe('The name of the AI Gateway route'),
      }),
      execute: async ({ routeName }) => ({
        routeName,
        auth: 'enabled',
        semanticCache: 'enabled',
        guardrails: 'enabled',
      }),
    }),
  },
  prompt: 'Check the AI Gateway policy for the production chat route.',
});

console.log(result.text);
console.log('Tool calls:', result.toolCalls);
```

## Build an agent

The SDK's agent loop runs the model, calls your tools, and feeds the results back until it reaches a
stopping condition. The model and tool traffic all flows through Kong:

```ts
import { Experimental_Agent as Agent, tool, stepCountIs } from 'ai';
import { z } from 'zod';
import { kong } from './kong-ai-gateway';

const gatewayAgent = new Agent({
  model: kong.chat('gpt-4o'),
  tools: {
    getRouteMetrics: tool({
      description: 'Return request and error counts for an AI Gateway route.',
      inputSchema: z.object({
        routeName: z.string(),
      }),
      execute: async ({ routeName }) => ({
        routeName,
        requests: 14820,
        errorRate: 0.004,
      }),
    }),
  },
  stopWhen: stepCountIs(10),
});

const result = await gatewayAgent.generate({
  prompt: 'Is the production chat route healthy? Summarize its request volume and error rate.',
});

console.log(result.text);
console.log('Steps taken:', result.steps.length);
```

## Route to multiple models

Instead of hard-coding provider model names in your app, configure client-facing model aliases with
[AI Proxy Advanced](/plugins/ai-proxy-advanced/). The application sends an alias such as `fast` or
`smart`, and Kong maps it to a real upstream model. You can change the upstream model, swap providers,
or add load balancing at the gateway without redeploying the app.

Add a target per alias in your Kong configuration:

{%- raw %}
```yaml
plugins:
- name: ai-proxy-advanced
  config:
    targets:
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: 'Bearer ${{ env "DECK_OPENAI_API_KEY" }}'
      model:
        provider: openai
        name: gpt-4o-mini
        model_alias: fast
    - route_type: llm/v1/chat
      auth:
        header_name: Authorization
        header_value: 'Bearer ${{ env "DECK_OPENAI_API_KEY" }}'
      model:
        provider: openai
        name: gpt-4o
        model_alias: smart
```
{% endraw -%}

Then select a model by alias in the SDK:

```ts
import { generateText } from 'ai';
import { kong } from './kong-ai-gateway';

// Fast, low-cost model for routine work.
const quick = await generateText({
  model: kong.chat('fast'),
  prompt: 'Write a one-line summary of this changelog entry.',
});

// Higher-capability model for complex work. Only the alias changes.
const detailed = await generateText({
  model: kong.chat('smart'),
  prompt: 'Compare three rollout strategies for a production AI application.',
});
```

{:.info}
> Model aliases require {{site.ai_gateway_name}} 3.14 or later. On earlier versions, send the upstream
> model name directly, for example `kong.chat('gpt-4o')`.

## Pass custom parameters

Standard generation parameters pass straight through to the upstream model:

```ts
import { generateText } from 'ai';
import { kong } from './kong-ai-gateway';

const { text } = await generateText({
  model: kong.chat('gpt-4o'),
  temperature: 0.3,
  maxOutputTokens: 512,
  maxRetries: 5,
  prompt: 'Draft a short incident summary for an AI Gateway latency spike.',
});

console.log(text);
```

## Generate images

To generate images, point the SDK's image model at a Route configured with the
`image/v1/images/generations` route type, then call `experimental_generateImage`:

```ts
import { experimental_generateImage as generateImage } from 'ai';
import { kong } from './kong-ai-gateway';

const { image } = await generateImage({
  model: kong.image('dall-e-3'),
  prompt: 'A clean isometric diagram of an API gateway routing traffic to several AI models',
  size: '1024x1024',
});

console.log(image.base64);
```

## Generate embeddings

To create embeddings, point the SDK at a Route configured with the `llm/v1/embeddings` route type, then
use `embed` or `embedMany`:

```ts
import { embed } from 'ai';
import { kong } from './kong-ai-gateway';

const { embedding } = await embed({
  model: kong.embedding('text-embedding-3-small'),
  value: 'Kong AI Gateway centralizes routing, auth, and observability for LLM traffic.',
});

console.log(embedding.length);
```

## Set up the Kong AI Gateway Route

If you do not already have a Route for Vercel AI SDK traffic, configure one with
[AI Proxy Advanced](/plugins/ai-proxy-advanced/) on your Kong Konnect Gateway control plane. The Plugin
owns the upstream provider credential, so the key never reaches the client.

Export the provider key for decK to inject:

```bash
export DECK_OPENAI_API_KEY='sk-YOUR-OPENAI-KEY'
```

Define a minimal chat-completions configuration in `kong.yaml`:

{%- raw %}
```yaml
_format_version: "3.0"

services:
- name: vercel-ai-sdk
  # Placeholder upstream; AI Proxy Advanced overrides this and calls the provider.
  url: https://api.openai.com
  routes:
  - name: vercel-ai-sdk
    paths:
    - /vercel-ai-sdk
    methods:
    - POST
    - OPTIONS
    strip_path: true
  plugins:
  - name: ai-proxy-advanced
    config:
      response_streaming: allow
      targets:
      - route_type: llm/v1/chat
        auth:
          header_name: Authorization
          header_value: 'Bearer ${{ env "DECK_OPENAI_API_KEY" }}'
        model:
          provider: openai
          name: gpt-4o
```
{% endraw -%}

Sync it to your Konnect control plane:

```bash
deck gateway sync kong.yaml \
  --konnect-addr https://us.api.konghq.com \
  --konnect-token 'kpat_YOUR-KONNECT-PAT' \
  --konnect-control-plane-name vercel-ai-sdk
```

This syncs into the `vercel-ai-sdk` Gateway control plane on Konnect. Change `--konnect-control-plane-name`
to target an existing control plane, and use `eu.api.konghq.com` or `au.api.konghq.com` if your Konnect
org is in the EU or AU region.

The SDK's `baseURL` is your gateway proxy URL plus this Route path, for example
`https://your-gateway-host/vercel-ai-sdk`. The OpenAI provider appends `/chat/completions` to that base
URL, which matches the `llm/v1/chat` Route. To support [images](#generate-images) or
[embeddings](#generate-embeddings), add Routes with the `image/v1/images/generations` and
`llm/v1/embeddings` route types.

## Add gateway controls without changing app code

Once the app points at Kong, platform teams can attach controls to the same Route without rewriting any
Vercel AI SDK calls:

- [Key Authentication](/plugins/key-auth/) to identify the calling application with an `apikey` header.
- [Rate Limiting](/plugins/rate-limiting/) to enforce per-app request budgets.
- [AI Prompt Guard](/plugins/ai-prompt-guard/) or [AI Semantic Prompt Guard](/plugins/ai-semantic-prompt-guard/) to block unsafe prompts before they reach the provider.
- [AI Semantic Cache](/plugins/ai-semantic-cache/) to serve repeated prompts without another upstream call.
- [OpenTelemetry](/plugins/opentelemetry/) and logging Plugins to capture AI traffic data.

If you add Key Authentication, send the Consumer key from the SDK with the `apikey` header. The upstream
provider key still stays in Kong:

```ts
import { createOpenAI } from '@ai-sdk/openai';

export const kong = createOpenAI({
  baseURL: `${process.env.KONNECT_AI_GATEWAY_URL}/vercel-ai-sdk`,
  apiKey: 'kong', // Not used by Kong; the provider key lives in the gateway.
  headers: {
    apikey: process.env.KONNECT_AI_GATEWAY_KEY ?? '', // Kong Consumer key for Key Authentication.
  },
});
```

The client keeps calling `kong.chat('fast')` or `kong.chat('smart')`. Kong applies the production
controls at the gateway layer. For a full walkthrough, see
[Authenticate OpenAI SDK clients with Key Auth](/how-to/authenticate-openai-sdk-clients-with-key-auth/).

## Use the Responses API

If your app uses the OpenAI Responses API by calling `kong('model')` instead of `kong.chat('model')`,
configure an AI Proxy Advanced target with the `llm/v1/responses` route type and point the SDK at that
Route. Use `kong.chat('model')` for the chat-completions setup shown throughout this guide.

## Troubleshooting

**The SDK returns 401 from Kong.** If the Route uses Key Authentication, confirm that the `apikey` header
carries a valid Kong Consumer key.

**The upstream provider returns 401.** Confirm that `DECK_OPENAI_API_KEY` holds a valid provider key and
that the AI Proxy Advanced target injects it as the `Authorization` header with the `Bearer ` prefix.

**The request does not match a target.** Confirm that the model in the SDK, such as `kong.chat('fast')`,
matches a `model.model_alias` (or `model.name`) in the AI Proxy Advanced configuration.

**Streaming buffers instead of returning tokens progressively.** Confirm that the Plugin uses
`response_streaming: allow` and that any infrastructure in front of Kong supports streaming responses.

## Next steps

- Use the [Basic LLM Routing cookbook](/cookbooks/basic-llm-routing/) for a deeper walkthrough of model aliases.
- Add [AI Semantic Cache](/plugins/ai-semantic-cache/) to reduce repeated LLM calls.
- Add [AI Prompt Guard](/plugins/ai-prompt-guard/) to enforce prompt policies.
- Review the [AI Proxy Advanced reference](/plugins/ai-proxy-advanced/) for providers, route types, and load-balancing options.
