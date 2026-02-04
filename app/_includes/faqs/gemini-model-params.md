You have several options, depending on the SDK and configuration:

- Use the **Gemini SDK**:

    1. Set [`llm_format`](/plugins/ai-proxy/reference/#schema--config-llm-format) to `gemini`.
    1. Use the Gemini provider.
    1. Configure parameters like [`temperature`](/plugins/ai-proxy/reference/#schema--config-model-options-temperature), [`top_p`](/plugins/ai-proxy/reference/#schema--config-model-options-top-p), and [`top_k`](/plugins/ai-proxy/reference/#schema--config-model-options-top-k) on the client side:
        ```python
        model = genai.GenerativeModel(
            'gemini-1.5-flash',
            generation_config=genai.types.GenerationConfig(
                temperature=0.7,
                top_p=0.9,
                top_k=40,
                max_output_tokens=1024
            )
        )
        ```

- Use the **OpenAI SDK** with the Gemini provider:
    1. Set [`llm_format`](/plugins/ai-proxy/reference/#schema--config-llm-format) to `openai`.
    1. You can configure parameters in one of three ways:
    - Configure them in the plugin only.
    - Configure them in the client only.
    - Configure them in both—the client-side values will override plugin config.