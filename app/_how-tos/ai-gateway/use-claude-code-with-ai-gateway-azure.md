---
title: Route Claude CLI traffic through {{site.ai_gateway}} and Azure
permalink: /ai-gateway/how-to/use-claude-code-with-ai-gateway-azure/
content_type: how_to

related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Configure {{site.ai_gateway}} to proxy Claude CLI traffic using Azure OpenAI models

products:
  - ai-gateway

works_on:
  - konnect

tools:
  - kongctl

prereqs:
  inline:
    - title: OpenAI API key
      include_content: md/ai-gateway/v2/prereqs/openai-kongctl

min_version:
  ai-gateway: '2.0'

tldr:
  q: How do I run Claude CLI through {{site.ai_gateway}} for Azure OpenAI models?
  a: Install Claude CLI, configure its API key helper, create a Gateway Service and Route, attach the AI Proxy plugin to forward requests to Claude, enable the File Log plugin to inspect traffic, and point Claude CLI to the local proxy endpoint so all LLM requests pass through the {{site.ai_gateway}} for monitoring and control.

---

## Configure the AI Proxy plugin



## Verify traffic through {{site.ai_gateway}}

Now, we can start a {{ site.claude_code }} session that points it to the local {{site.ai_gateway}} endpoint:

{:.warning}
> Ensure that `ANTHROPIC_MODEL` matches the model you deployed in Azure.

```sh
ANTHROPIC_BASE_URL=http://localhost:8000/anything \
ANTHROPIC_MODEL=YOUR_AZURE_MODEL \
claude
```

{{ site.claude_code }} asks for permission before it runs tools or interacts with files:

```text
I'll need permission to work with your files.

This means I can:
- Read any file in this folder
- Create, edit, or delete files
- Run commands (like npm, git, tests, ls, rm)
- Use tools defined in .mcp.json

Learn more ( https://docs.claude.com/s/claude-code-security )

❯ 1. Yes, continue
2. No, exit
```
{:.no-copy-code}

Select **Yes, continue**. The session starts. Ask a simple question to confirm that requests reach {{site.ai_gateway}}.

```text
Tell me about Vienna Oribasius manuscript.
```

{{ site.claude_code }} might prompt you approve its web search for answering the question. When you select **Yes**, {{ site.claude }} will produce a full-length response to your request:

```text
The "Vienna Oribasius manuscript" refers to a famous illustrated medical
codex that preserves the works of Oribasius of Pergamon, a noted Greek
physician who lived in the 4th century CE. Oribasius was a compiler of
earlier medical knowledge, and his writings form an important link in the
transmission of Greco-Roman medical science to the Byzantine, Islamic, and
later European worlds.
```
{:.no-copy-code}

Next, inspect the {{site.ai_gateway}} logs to verify that the traffic was proxied through it:

```sh
docker exec kong-quickstart-gateway cat /tmp/claude.json | jq
```

You should find an entry that shows the upstream request made by {{ site.claude_code }}. A typical log record looks like this:

```json
{
  "...": "...",
  "headers": {
    ...
    "user-agent": "claude-cli/2.0.37 (external, cli)",
    "content-type": "application/json",
    ...
  },
  "method": "POST",
  ...
   "ai": {
    "meta": {
        "request_mode": "oneshot",
        "response_model": "gpt-4.1-2025-04-14",
        "request_model": "gpt-4.1",
        "llm_latency": 4606,
        "provider_name": "azure",
        "azure_deployment_id": "gpt-4.1",
        "plugin_id": "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx",
        "azure_api_version": "2024-12-01-preview",
        "azure_instance_id": "example-azure-openai"
      },
      "usage": {
        "completion_tokens": 414,
        "completion_tokens_details": {
          "accepted_prediction_tokens": 0,
          "audio_tokens": 0,
          "rejected_prediction_tokens": 0,
          "reasoning_tokens": 0
        },
        "total_tokens": 11559,
        "cost": 0,
        "time_per_token": 11.125603864734,
        "time_to_first_token": 4605,
        "prompt_tokens": 11145,
        "prompt_tokens_details": {
          "audio_tokens": 0,
          "cached_tokens": 11008,
          "cached_tokens_details": {}
        }
      }
    }
  },
```
{:.no-copy-code}

This output confirms that {{ site.claude_code }} routed the request through {{site.ai_gateway}} using the `gpt-4.1` Azure AI model we selected while starting the {{ site.claude_code }} session.
