---
title: "{{ site.claude_code }} compatibility testing"
content_type: reference
layout: reference

description: "Reference for how Kong tests each {{ site.claude_code }} release through {{site.ai_gateway}}. Covers tested provider modes, test schedule, and verified request headers and body fields."

breadcrumbs:
  - /ai-gateway/
  - /ai-gateway/ai-clis/

products:
  - ai-gateway

works_on:
  - on-prem
  - konnect

tags:
  - ai
  - anthropic
  - cli
  - compatibility

related_resources:
  - text: "{{ site.claude_code }} release known issues"
    url: /ai-gateway/claude-code-known-issues/
  - text: "Proxy AI CLI tools through {{site.ai_gateway}}"
    url: /ai-gateway/ai-clis/
  - text: "Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic"
    url: /ai-gateway/use-claude-code-with-ai-gateway-anthropic/
  - text: "{{ site.claude_code }} gateway compatibility guide"
    url: https://code.claude.com/docs/en/llm-gateway-protocol
---

Kong runs automated compatibility tests on each new {{ site.claude_code }} release through {{site.ai_gateway}}.
These tests verify that {{site.ai_gateway}} forwards {{ site.claude_code }} requests to model providers without breaking tool calls, subagents, or required protocol fields.

When a release fails in a tested mode, Kong lists the affected release, what breaks, and how to avoid it in [{{ site.claude_code }} release known issues](/ai-gateway/claude-code-known-issues/).

## Provider modes

A {{ site.claude_code }} provider mode sets which provider API {{ site.claude_code }} calls and which settings point it at {{site.ai_gateway}}.
The cloud sign-in skip switch stops {{ site.claude_code }} from signing in to the cloud provider directly, so {{site.ai_gateway}} handles authentication.

Kong tests each release in the following provider modes:

{% include md/ai-gateway/v2/claude-code-provider-modes.md %}

The compatibility tests don't cover the Amazon Bedrock mode (`CLAUDE_CODE_USE_BEDROCK`) or the Google Vertex AI mode (`CLAUDE_CODE_USE_VERTEX`).

## When tests run

Kong checks the {{ site.claude_code }} `latest` release channel every hour.
Each test run uses the newest {{ site.claude_code }} release with the `latest` {{site.ai_gateway}} image.
Kong runs the tests again whenever a new {{ site.claude_code }} release or a new `latest` {{site.ai_gateway}} image is available.

Test results apply only to the `latest` {{site.ai_gateway}} image.
Kong doesn't test earlier {{site.ai_gateway}} releases again.

## What the tests verify

The compatibility tests send each inference request through {{site.ai_gateway}} to a mock model provider that Kong runs for testing.
The gateway setup follows [Route Claude CLI traffic through {{site.ai_gateway}} and Anthropic](/ai-gateway/use-claude-code-with-ai-gateway-anthropic/).

Anthropic's [gateway compatibility guide](https://code.claude.com/docs/en/llm-gateway-protocol) lists headers and body fields that a gateway forwards unchanged.
In each tested provider mode, the tests verify the following behaviors:

* **Tool calls and subagents**: {{ site.claude_code }} completes a session that includes a tool call and a subagent.
* **Header forwarding**: {{site.ai_gateway}} forwards the `anthropic-version` and `anthropic-beta` request headers unchanged.
  In the Claude Platform on AWS mode, the tests also verify that {{site.ai_gateway}} forwards the `anthropic-workspace-id` header unchanged.
* **Request body forwarding**: {{site.ai_gateway}} forwards the `system`, `messages`, `tools`, `thinking`, `context_management`, and `output_config` request body fields unchanged.
  {{site.ai_gateway}} can reorder JSON keys or change whitespace or encoding, because the tests compare field values.
* **Token counting (Anthropic API mode)**: A separate test sends a token count request to `/v1/messages/count_tokens` through {{site.ai_gateway}}.
  The test verifies that the model provider receives the same `messages` field and that {{site.ai_gateway}} returns the model provider's count unchanged.
