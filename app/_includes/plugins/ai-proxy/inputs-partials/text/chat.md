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
    ]
}
```

{% new_in 3.9 %} With Amazon Bedrock, you can include your [guardrail](https://docs.aws.amazon.com/bedrock/latest/userguide/guardrails.html) configuration in the request:

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