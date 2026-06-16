You can configure model generation parameters when calling Gemini through {{site.ai_gateway}}:

- **Using the {{ site.gemini }} SDK**:

    1. Create an [AI Provider](/ai-gateway/entities/ai-provider/) for Gemini and an [AI Model](/ai-gateway/entities/ai-model/) that references it.
    1. Configure parameters like `temperature`, `top_p`, and `top_k` on the client side:
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

- **Using the OpenAI SDK** with {{site.ai_gateway}}:
    1. Create an [AI Provider](/ai-gateway/entities/ai-provider/) for Gemini with `llm_format` set to `openai`.
    1. You can configure parameters in one of three ways:
        - Configure them in the [AI Model](/ai-gateway/entities/ai-model/) only.
        - Configure them in the client only.
        - Configure them in both—the client-side values will override the model config.
