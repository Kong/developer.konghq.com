Add a `guardrailConfig` object to your request body:

```json
      {
          "messages": [
              {
                  "role": "system",
                  "content": "You are a scientist."
              },
              {
                  "role": "user",
                  "content": "What is the Boltzmann equation?"
              }
          ],
          "guardrailConfig": {
              "guardrailIdentifier": "$GUARDRAIL-IDENTIFIER",
              "guardrailVersion": "1",
              "trace": "enabled"
          }
      }
```

This feature requires {{site.base_gateway}} 3.9 or later. For more details, see [Guardrails and content safety](/ai-gateway/#guardrails-and-content-safety) and the [AWS Bedrock guardrails documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html).