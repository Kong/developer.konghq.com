---
min_version:
  ai-gateway: '2.0'
works_on:
  - konnect
products:
  - ai-gateway
content_type: policy
---

The AI Prompt Template Policy lets you provide tuned AI prompts to users.
Users only need to fill in the blanks with variable placeholders in the following format: `{% raw %}{{variable}}{% endraw %}`.

This lets admins set up templates, which can then be used by anyone in the organization. It also allows admins to present an LLM
as an API in its own right - for example, a bot that can provide software class examples and/or suggestions.

This Policy also sanitizes string inputs to ensure that JSON control characters are escaped, preventing arbitrary prompt injection.

## How it works

When activated, the template restricts LLM usage to the predefined templates. They are defined in the following format:

{% entity_example %}
type: policy
data:
  name: ai-prompt-template
  config:
    templates:
       name: sample-template
       template: |-
          {
            "messages": [
              {
                "role": "user",
                "content": "Explain to me what {% raw %}{{thing}}{% endraw %} is."
              }
            ]
          }
formats:
  - konnect-api
{% endentity_example %}


When calling a template, replace the content of `messages` (`llm/v1/chat`) or `prompt` (`llm/v1/completions`) with a template reference, using the following format:
```json
{
  "messages": "{template://sample-template}",
  "properties": {
    "thing": "gravity"
  }
}
```

By default, requests that don't use a template are still be passed to the LLM. However, this can be configured using the [`config.allow_untemplated_requests`](/ai-gateway/policies/ai-prompt-template/reference/#schema--config-allow-untemplated-requests) parameter. If this parameter is set to `false`, requests that don't use a template will return a `400 Bad Request` response.
