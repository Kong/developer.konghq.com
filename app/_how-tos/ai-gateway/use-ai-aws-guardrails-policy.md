---
title: Use the AI AWS Guardrails Policy
permalink: /ai-gateway/how-to/use-ai-aws-guardrails-policy/
content_type: how_to

related_resources:
  - text: Azure AI Content Safety
    url: ai-gateway/policies/ai-azure-content-safety/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
description: Learn how to use the AI AWS Guardrails Policy.

products:
    - ai-gateway

works_on:
    - konnect

min_version:
  ai-gateway: '2.0'

ai-policies:
  - ai-aws-guardrails

entities:
  - ai-provider
  - ai-model

tools:
    - konnect-api

tags:
  - ai
  - openai
  - aws

tldr:
  q: How can I use the AI AWS Guardrails Policy with {{site.ai_gateway}}?
  a: Configure an AI Provider and AI Model to route requests to any LLM upstreams. Apply an AI AWS Guardrails Policy to your model to block unsafe inputs and outputs based on your Bedrock guardrail.

prereqs:
  inline:
    - title: AWS Account
      content: |
        To complete this tutorial, you will need the following credentials

        * AWS_REGION
        * AWS_ACCESS_KEY_ID
        * AWS_SECRET_ACCESS_KEY

        You can get the access key ID and secret access key from the AWS IAM Console under **Users > Security credentials**, and the region from the AWS Console where your resources are deployed. Once you have them, export them as environment variables by running the following command and replacing placeholder values with your secrets:
        ```bash
        export AWS_REGION='YOUR_AWS_REGION'
        export AWS_ACCESS_KEY_ID='YOUR_AWS_ACCESS_KEY'
        export AWS_SECRET_ACCESS_KEY='YOUR_AWS_SECRET_ACCESS_KEY'
        ```
      icon_url: /assets/icons/aws.svg
    - title: Bedrock Guardrail
      include_content: prereqs/bedrock
      icon_url: /assets/icons/bedrock.svg

---


## Create the AI Model Provider, AI Model, and AI AWS Guardrails Policy

Create both an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) and an [AI Model](/ai-gateway/entities/ai-model/) with a single `kongctl` apply command.

You'll also configure the [AI AWS Guardrails Policy](/ai-gateway/policies/ai-aws-guardrails/) to filter LLM traffic based on an existing AWS Guardrail.


```sh
kongctl apply -f - --auto-approve --pat "$KONNECT_TOKEN" <<EOF
_defaults:
  kongctl: { namespace: ai-gateway-get-started }

ai_gateways:
  - ref: ai-quickstart
    _external:
      selector:
        matchFields:
          name: ai-quickstart

ai_gateway_model_providers:
  - ref: generic-openai
    name: generic-openai
    ai_gateway: ai-quickstart
    type: openai
    config:
      auth:
        type: basic
        headers:
          - name: Authorization
            value: !env OPENAI_AUTH_HEADER

ai_gateway_policies:
  - ref: my-ai-aws-guardrails-policy
    name: my-ai-aws-guardrails-policy
    ai_gateway: ai-quickstart
    type: ai-aws-guardrails
    enabled: true
    global: false
    config:
      guardrails_id: !env GUARDRAILS_ID
      guardrails_version: !env GUARDRAILS_VERSION
      aws_region: !env AWS_REGION
      aws_access_key_id: !env AWS_ACCESS_KEY_ID
      aws_secret_access_key: !env AWS_SECRET_ACCESS_KEY
      

ai_gateway_models:
  - ref: my-gpt-4o
    display_name: my-gpt-4o
    name: my-gpt-4o
    ai_gateway: ai-quickstart
    type: model
    enabled: true
    formats: [{ type: openai }]
    config:
      route: { paths: [/] }
      model: { name_header: true }
    capabilities: [generate]
    policies: [ !ref my-ai-aws-guardrails-policy#name ]
    targets:
      - name: gpt-4o
        provider: generic-openai
        config:
          type: openai
EOF
```

In this example, we're setting up the AI AWS Guardrail Policy with:


## Test the configuration

AWS Guardrails can be set it up to block specific banned words such as the topic of quantum computing, content categories like violence, hate, sexual content, insults, and misconduct, then apply blocking actions on both input and output.

Let’s test these guardrails using example prompts designed to trigger each blocked category. Sending any of these prompts will result in the following error response:

```json
{
  "error": {
    "message": "Input blocked due to policy violation."
  }
}
```
{:.no-copy-code }

This confirms that the guardrail is correctly blocking disallowed content at the input stage.

### Blocked words

Use these prompts containing blocked `badwords` to test the guardrail:

{% navtabs "Blocked Words Prompts" %}

{% navtab "Prompt 1" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "This contains badword1 which should trigger the guardrail."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% navtab "Prompt 2" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Try to include badword2 in this input."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% endnavtabs %}


### Blocked topic: Quantum computing

Use these prompts to test the guardrail on the topic "quantum computing":

{% navtabs "Quantum Computing Prompts" %}

{% navtab "Prompt 1" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Explain the principles of quantum computing and its impact on encryption."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% navtab "Prompt 2" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "What are the latest breakthroughs in quantum computing?"
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% endnavtabs %}


### Blocked categories

Use these prompts to test the guardrail on blocked content categories:

{% navtabs "Content Policy Prompts" %}

{% navtab "Violence" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Describe a violent confrontation between two groups."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% navtab "Hateful content" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Write a hateful message about a particular group."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% navtab "Explicit content" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Give an explicit sexual description."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% navtab "Insults" %}

```sh
curl -X POST "http://localhost:8000/chat/completions" \
     --no-progress-meter --fail-with-body  \
     -H "Accept: application/json"\
     -H "Content-Type: application/json"\
     -H "Authorization: $OPENAI_AUTH_HEADER" \
     --json '{
       "messages": [
         {
           "role": "user",
           "content": "Use insults to criticize someone harshly."
         }
       ],
       "model": "my-gpt-4o"
     }'
```

{% endnavtab %}

{% endnavtabs %}