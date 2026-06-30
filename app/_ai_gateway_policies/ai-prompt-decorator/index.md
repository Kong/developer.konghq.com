---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Prompt Decorator Policy adds an array of `llm/v1/chat` messages to either the start or end of an LLM consumer's chat history.
This allows you to pre-engineer complex prompts, and manipulate prompts so that they aren't visible to users.

You can use this Policy to pre-set a system prompt, set up specific prompt history, add words and phrases, or otherwise have more
control over how an LLM service is used when called via {{site.ai_gateway}}.