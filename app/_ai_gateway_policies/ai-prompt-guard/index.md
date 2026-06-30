---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Prompt Guard Policy lets you configure a series of [PCRE-compatible](https://www.pcre.org/) regular expressions as allow or deny lists,
to guard against misuse of text completion requests.

You can use this Policy to allow or block specific prompts, words, phrases, or otherwise have more control over how an LLM service is
used when called via {{site.ai_gateway}}.

It does this by scanning all chat messages where the role is `user` for the specific expressions set.

You can use a combination of `allow` and `deny` rules to preserve integrity and compliance when serving an LLM service using {{site.ai_gateway}}.

* **For `llm/v1/chat` type models**: You can optionally configure the Policy to ignore existing chat history, wherein it will only scan the trailing `user` message.
* **For `llm/v1/completions` type models**: There is only one `prompt` field, thus the whole prompt is scanned on every request.

## How it works

This Policy matches lists of regular expressions to requests routed through the {{site.ai_gateway}}.

The matching behavior is as follows:
* If any `deny` expressions are set, and the request matches any regex pattern in the `deny` list, the caller receives a 400 Bad Request response.
* If any `allow` expressions are set, but the request matches none of the allowed expressions, the caller also receives a 400 Bad Request response.
* If any `allow` expressions are set, and the request matches one of the `allow` expressions, the request passes through to the LLM.
* If there are both `deny` and `allow` expressions set, the `deny` condition takes precedence over `allow`. Any request that matches an entry in the `deny` list will return a 400 response, even if it also matches an expression in the `allow` list. If the request does not match an expression in the `deny` list, then it must match an expression in the `allow` list to be passed through to the LLM.

## Best practices

Configure the AI Prompt Guard Policy to detect hidden unicode characters that attackers commonly use to embed malicious instructions in user input:

{% entity_example %}
type: policy
data:
  name: ai-prompt-guard
  config:
    deny_patterns:
    - (\xE2\x80[\x8B-\x8D]|\xEF\xBB\xBF)
    - \xE2\x80[\xAA-\xAE]
    - \xE2\x81[\xA0-\xAF]
    - \xF3\xA0\x80[\xA0-\xBF]|\xF3\xA0\x81[\x80-\xBF]
formats:
  - konnect-api
{% endentity_example %}

In this example:
- `(\xE2\x80[\x8B-\x8D]|\xEF\xBB\xBF)`: Detects zero-width characters (`U+200B`-`U+200D`, `U+FEFF`)
- `\xE2\x80[\xAA-\xAE]`: Detects bidirectional text controls (`U+202A`-`U+202E`)
- `\xE2\x81[\xA0-\xAF]`: Detects format controls (`U+2060`-`U+206F`)
- `\xF3\xA0\x80[\xA0-\xBF]|\xF3\xA0\x81[\x80-\xBF]`: Detects unicode tag characters (`U+E0020`-`U+E007F`)

These patterns block invisible characters that can hide prompt injection attempts. Zero-width and bidirectional control characters render as blank space in most interfaces but remain visible to the LLM, allowing attackers to insert hidden commands.