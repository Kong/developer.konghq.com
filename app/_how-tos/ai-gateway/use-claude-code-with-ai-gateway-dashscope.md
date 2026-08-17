---
title: Route Claude CLI traffic through {{site.ai_gateway}} and DashScope
permalink: /ai-gateway/use-claude-code-with-ai-gateway-dashscope/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic to an Alibaba Cloud DashScope model.

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

min_version:
  ai-gateway: '2.0'

tags:
  - ai
  - dashscope

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} against a DashScope model?
  a: Create an AI Model Provider for Alibaba Cloud DashScope and an AI Model with the `anthropic` format that targets it, then point {{ site.claude_code }}'s `ANTHROPIC_BASE_URL` at your local {{site.ai_gateway}} endpoint so all requests pass through the gateway for monitoring and control.

prereqs:
  konnect:
    - name: KONG_NGINX_HTTP_CLIENT_BODY_BUFFER_SIZE
      value: 2m
  inline:
    - title: DashScope
      icon_url: /assets/icons/dashscope.svg
      content: |
        Get an API key from the [Alibaba Cloud DashScope console](https://dashscope.aliyuncs.com/) and export it as the **full `Authorization` header value** (including the `Bearer` prefix):

        ```sh
        export DASHSCOPE_AUTH_HEADER="Bearer YOUR_DASHSCOPE_KEY"
        ```
    - title: Claude Code CLI
      icon_url: /assets/icons/third-party/claude.svg
      include_content: prereqs/claude-code

---

## Create the AI Model Provider and AI Model entities

DashScope serves the Qwen model family through a native Anthropic-compatible Messages API, so {{ site.claude_code }} can talk to it natively. 

Create an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) entity to define your connection and store your authentication credentials.

Create an [AI Model](/ai-gateway/entities/ai-model/) entity to declare which upstream models are available, configure how client requests are routed, and specify which AI Model Provider to use.

{% entity_examples %}
ai_gateway_model_providers:
  - ref: dashscope
    ai_gateway: !lookup name:ai-quickstart
    name: dashscope
    type: dashscope
    display_name: "Alibaba Cloud DashScope"
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env DASHSCOPE_AUTH_HEADER
ai_gateway_models:
  - ref: claude-code-qwen
    ai_gateway: !lookup name:ai-quickstart
    name: claude-code-qwen
    display_name: "Claude Code - DashScope Qwen"
    type: model
    enabled: true
    formats:
      - type: anthropic
    config:
      route:
        paths:
          - /
        model:
          body_param: model
          values:
            - qwen-plus
    capabilities:
      - generate
    targets:
      - name: qwen-plus
        provider: dashscope
        config:
          type: dashscope
          international: true
          max_tokens: 8192
          temperature: 1.0
{% endentity_examples %}

This example uses the following settings:

 * `type: dashscope`: Connects to the Alibaba Cloud DashScope API as an AI Model Provider.
 * `capabilities: [generate]`: For a model using the `anthropic` format, `generate` creates a `/v1/messages` endpoint matching Anthropic's native Messages API.
 * `formats: [{ type: anthropic }]`: Accepts Anthropic-format requests to the AI Model entity, matching what {{ site.claude_code }} sends.
 * `config.route.model: { body_param: model, values: [qwen-plus] }`: The model name {{ site.claude_code }} should send in each request, which you can set with the `ANTHROPIC_MODEL` variable or `--model` option.
 * `route.paths: [/]`: Configures the custom base path where this model's routes will be accessible. Setting this to a unique value avoids clashes when you have multiple AI Models.
 * `targets[0].config.international: true`: Uses DashScope's international endpoint (`dashscope-intl.aliyuncs.com`). This is the default. If your DashScope key belongs to a mainland China account, set this to `false` so requests reach `dashscope.aliyuncs.com` instead.

## Verify traffic through {{site.ai_gateway}}

Before starting {{ site.claude_code }}, confirm the route works by sending an Anthropic Messages API request directly:

{% validation request-check %}
url: /v1/messages
status_code: 200
method: POST
headers:
    - 'Accept: application/json'
    - 'Content-Type: application/json'
    - 'Authorization: $DASHSCOPE_AUTH_HEADER'
body:
  model: qwen-plus
  max_tokens: 16
  messages:
    - role: 'user'
      content: "Reply with just: ok"
{% endvalidation %}

## Run {{ site.claude_code }}

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

{% validation claude-code %}
prompt: Tell me about the Madrid Skylitzes manuscript.
model: qwen-plus
base_url: http://localhost:8000/
{% endvalidation %}


{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
The Madrid Skylitzes is a remarkable 12th-century illuminated Byzantine
manuscript that represents one of the most important surviving examples
of medieval historical documentation. Here are the key details:

What it is

The Madrid Skylitzes is the only surviving illustrated manuscript of John
Skylitzes' "Synopsis of Histories" (Σύνοψις Ἱστοριῶν), which chronicles
Byzantine history from 811 to 1057 CE - covering the period from the death
of Emperor Nicephorus I to the deposition of Michael VI.

Artistic Significance

- 574 miniature paintings (with about 100 lost over time)
- Lavishly decorated with gold leaf, vibrant pigments, and intricate
detailing
- Depicts everything from imperial coronations and battles to daily life
in Byzantium
- The only surviving Byzantine illuminated chronicle written in Greek

Unique Collaboration

The manuscript is believed to be the work of 7 different artists from
various backgrounds:
- 4 Italian artists
- 1 English or French artist
- 2 Byzantine artists
```
{:.no-copy-code}