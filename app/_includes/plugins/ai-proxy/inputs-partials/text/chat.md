```json
{
    "messages": [
        {
            "role": "system",
            "content": "You are a scientist."
        },
        {
            "role": "user",
            "content": "What is the theory of relativity?"
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
            "content": "What is the theory of relativity?"
        }
    ],
      "guardrailConfig": {
              "guardrailIdentifier":"<guardrail_identifier>",
              "guardrailVersion":"1",
              "trace":"enabled"
          }
}
```