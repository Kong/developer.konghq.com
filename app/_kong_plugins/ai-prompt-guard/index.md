---
title: 'AI Prompt Guard'
name: 'AI Prompt Guard'

content_type: plugin

publisher: kong-inc
description: 'Check llm/v1/chat or llm/v1/completions requests against a list of allowed or denied expressions'


products:
    - ai-gateway
    - gateway

works_on:
    - on-prem
    - konnect

min_version:
    gateway: '3.6'

topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless
icon: ai-prompt-guard.png

categories:
  - ai

tags:
  - ai

search_aliases:
  - ai
  - llm
  - artificial
  - intelligence
  - language
  - model

related_resources:
  - text: AI Semantic Prompt Guard plugin
    url: /plugins/ai-semantic-prompt-guard/
---

The AI Prompt Guard plugin lets you to configure a series of [PCRE-compatible](https://www.pcre.org/) regular expressions as allow or deny lists,
to guard against misuse of `llm/v1/chat` or `llm/v1/completions` requests.

You can use this plugin to allow or block specific prompts, words, phrases, or otherwise have more control over how an LLM service is
used when called via {{site.base_gateway}}.

It does this by scanning all chat messages where the role is `user` for the specific expressions set.

You can use a combination of `allow` and `deny` rules to preserve integrity and compliance when serving an LLM service using {{site.base_gateway}}.

* **For `llm/v1/chat` type models**: You can optionally configure the plugin to ignore existing chat history, wherein it will only scan the trailing `user` message.
* **For `llm/v1/completions` type models**: There is only one `prompt` field, thus the whole prompt is scanned on every request.

{% include plugins/ai-plugins-note.md %}

## How it works

The plugin matches lists of regular expressions to requests through AI Proxy.

The matching behavior is as follows:
* If any `deny` expressions are set, and the request matches any regex pattern in the `deny` list, the caller receives a 400 response.
* If any `allow` expressions are set, but the request matches none of the allowed expressions, the caller also receives a 400 response.
* If any `allow` expressions are set, and the request matches one of the `allow` expressions, the request passes through to the LLM.
* If there are both `deny` and `allow` expressions set, the `deny` condition takes precedence over `allow`. Any request that matches an entry in the `deny` list will return a 400 response, even if it also matches an expression in the `allow` list. If the request does not match an expression in the `deny` list, then it must match an expression in the `allow` list to be passed through to the LLM.

## Best practices

Configure the AI Prompt Guard plugin to detect hidden unicode characters that attackers commonly use to embed malicious instructions in user input:

{% entity_examples %}
entities:
  plugins:
    - name: ai-prompt-guard
      config:
        deny_patterns:
        # Zero Width Characters (U+200B-U+200D, U+FEFF)
        - (\xE2\x80[\x8B-\x8D]|\xEF\xBB\xBF)

        # Bidirectional Text Controls (U+202A-U+202E)
        - \xE2\x80[\xAA-\xAE]

        # Format Controls (U+2060-U+206F)
        - \xE2\x81[\xA0-\xAF]

        # Unicode Tag Characters (U+E0020-U+E007F)
        - \xF3\xA0\x80[\xA0-\xBF]|\xF3\xA0\x81[\x80-\xBF]
formats:
  - deck
{% endentity_examples %}

These patterns block invisible characters that can hide prompt injection attempts. Zero-width and bidirectional control characters render as blank space in most interfaces but remain visible to the LLM, allowing attackers to insert hidden commands.