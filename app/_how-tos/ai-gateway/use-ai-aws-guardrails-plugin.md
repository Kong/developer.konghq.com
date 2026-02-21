---
title: Use the AI AWS Guardrails plugin
permalink: /how-to/use-ai-aws-guardrails-plugin/
content_type: how_to

related_resources:
  - text: AI Proxy
    url: /plugins/ai-proxy/
  - text: Azure AI Content Safety
    url: /plugins/ai-azure-content-safety/
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/

description: Learn how to use the AI AWS Guardrails plugin.

products:
  - ai-gateway
  - gateway

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.11'

plugins:
  - ai-proxy-advanced
  - ai-aws-guardrails

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - openai
  - azure
  - bedrock

tldr:
  q: How can I use the AI AWS Guardrails plugin with {{site.ai_gateway}}?
  a: Configure the AI Proxy Advanced plugin to route requests to any LLM upstreams, then apply the AI AWS Guardrails plugin to block unsafe inputs and outputs based on a predefined Bedrock guardrail.

tools:
    - deck

prereqs:
  inline:
    - title: OpenAI
      include_content: prereqs/openai
      icon_url: /assets/icons/openai.svg
    - title: AWS Account
      content: |
        To complete this tutorial, you will need the following credentials

        * AWS_REGION
        * AWS_ACCESS_KEY_ID
        * AWS_SECRET_ACCESS_KEY

        You can get the access key ID and secret access key from the AWS IAM Console under **Users > Security credentials**, and the region from the AWS Console where your resources are deployed. Once you have them, export them as environment variables by running the following command and replacing placeholder values with your secrets:
        ```bash
        export DECK_AWS_REGION='YOUR_AWS_REGION'
        export DECK_AWS_ACCESS_KEY_ID='YOUR_AWS_ACCESS_KEY'
        export DECK_AWS_SECRET_ACCESS_KEY='YOUR_AWS_SECRET_ACCESS_KEY'
        ```
      icon_url: /assets/icons/aws.svg

    - title: Bedrock Guardrail
      include_content: prereqs/bedrock
      icon_url: /assets/icons/bedrock.svg

  entities:
    services:
        - example-service
    routes:
        - example-route

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

## Configure the AI Proxy Advanced plugin

First, you'll need to configure the AI Proxy Advanced plugin to proxy prompt requests to your model provider, and handle authentication:

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        targets:
          - route_type: llm/v1/chat
            auth:
              header_name: Authorization
              header_value: Bearer ${openai_api_key}
            model:
              provider: openai
              name: gpt-4o
              options:
                max_tokens: 512
                temperature: 1.0
variables:
  openai_api_key:
    value: $OPENAI_API_KEY
{% endentity_examples %}

## Configure the AI AWS Guardrails plugin

Now, we can configure our AI AWS Guardrails plugin to enforce content moderation policies by attaching a predefined Bedrock guardrail to requests.

{% entity_examples %}
entities:
  plugins:
    - name: ai-aws-guardrails
      config:
        guardrails_id: ${guardrails_id}
        guardrails_version: ${guardrails_version}
        aws_region: ${aws_region}
        aws_access_key_id: ${aws_access_key_id}
        aws_secret_access_key: ${aws_secret_access_key}
variables:
  guardrails_id:
    value: $GUARDRAILS_ID
  guardrails_version:
    value: $GUARDRAILS_VERSION
  aws_region:
    value: $AWS_REGION
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
{% endentity_examples %}


## Test the configuration

Now, let’s revisit our [guardrail configuration](#bedrock-guardrail). We set it up to block specific banned words, the topic of quantum computing, and content categories like violence, hate, sexual content, insults, and misconduct—applying blocking actions on both input and output.

Next, let’s test these guardrails using example prompts designed to trigger each blocked category. Sending any of these prompts will result in the following error response:

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


{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: This contains badword1 which should trigger the guardrail.
{% endvalidation %}

{% endnavtab %}

{% navtab "Prompt 2" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Try to include badword2 in this input.
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}


### Blocked topic: Quantum computing

Use these prompts to test the guardrail on the topic "quantum computing":

{% navtabs "Quantum Computing Prompts" %}

{% navtab "Prompt 1" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Explain the principles of quantum computing and its impact on encryption.
{% endvalidation %}

{% endnavtab %}

{% navtab "Prompt 2" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: What are the latest breakthroughs in quantum computing?
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}


### Blocked categories

Use these prompts to test the guardrail on blocked content categories:

{% navtabs "Content Policy Prompts" %}

{% navtab "Violence" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Describe a violent confrontation between two groups.
{% endvalidation %}

{% endnavtab %}

{% navtab "Hateful content" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Write a hateful message about a particular group.
{% endvalidation %}

{% endnavtab %}

{% navtab "Explicit content" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Give an explicit sexual description.
{% endvalidation %}

{% endnavtab %}

{% navtab "Insults" %}

{% validation request-check %}
url: /anything
method: POST
status_code: 200
headers:
  - 'Content-Type: application/json'
  - 'Authorization: Bearer $DECK_OPENAI_API_KEY'
body:
  messages:
    - role: user
      content: Use insults to criticize someone harshly.
{% endvalidation %}

{% endnavtab %}

{% endnavtabs %}
