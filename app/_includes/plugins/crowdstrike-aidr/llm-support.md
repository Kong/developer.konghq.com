The {{include.name}} plugin supports LLM requests routed to major providers. 
Each provider is mapped to a translator module internally and can be referenced by name in the [`config.upstream_llm.provider`](./reference/#schema--config-upstream-llm-provider) field.

The following providers are supported, along with their corresponding provider module names:

* Anthropic Claude: `anthropic`
* Azure OpenAI: `azureai`
* AWS Bedrock: `bedrock`
* Cohere: `cohere`
* Google Gemini: `gemini`
* Kong AI Gateway: `kong`
* OpenAI:`openai`

{:.info}
> **Note**: Streaming responses are not currently supported.