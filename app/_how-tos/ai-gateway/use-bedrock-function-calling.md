---
title: Use AWS Bedrock function calling with AI Proxy Advanced
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: AWS Bedrock Converse API
    url: https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_Converse.html
breadcrumbs:
 - /ai-gateway/
permalink: /how-tos/use-bedrock-function-calling/

description: "Configure the AI Proxy Advanced plugin to use AWS Bedrock's Converse API for function calling with Cohere Command R."

products:
  - gateway
  - ai-gateway

works_on:
  - on-prem
  - konnect

min_version:
  gateway: '3.10'

plugins:
  - ai-proxy-advanced

entities:
  - service
  - route
  - plugin

tags:
  - ai
  - bedrock
  - native-apis

tldr:
  q: How do I use AWS Bedrock function calling with the AI Proxy Advanced plugin?
  a: |
    Configure AI Proxy Advanced with the `bedrock` provider, `llm_format: bedrock`, and `llm/v1/chat` route type. Point a Boto3 client at the {{site.ai_gateway}} route. The model can request tool calls, and the client sends results back through the same route.

tools:
  - deck

prereqs:
  inline:
    - title: AWS credentials and Bedrock model access
      content: |
        You must have AWS credentials with Bedrock permissions:

        - **AWS Access Key ID**: Your AWS access key
        - **AWS Secret Access Key**: Your AWS secret key
        - **Region**: AWS region where Bedrock is available (for example, `us-west-2`)

        1. Enable the Cohere Command R model in the [AWS Bedrock console](https://console.aws.amazon.com/bedrock/) under **Model Access**. Navigate to **Bedrock** > **Model access** and request access to `cohere.command-r-v1:0`.

        2. Export the required values as environment variables:
           ```sh
           export DECK_AWS_ACCESS_KEY_ID="<your-access-key-id>"
           export DECK_AWS_SECRET_ACCESS_KEY="<your-secret-access-key>"
           export DECK_AWS_REGION="us-west-2"
           ```
      icon_url: /assets/icons/aws.svg
    - title: Python, Boto3, and requests library
      content: |
        Install Python 3 and the required libraries:
        ```sh
        pip install boto3
        ```
      icon_url: /assets/icons/python.svg
  entities:
    services:
      - ai-proxy
    routes:
      - openai-chat

cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: What is function calling in Bedrock?
    a: |
      Function calling (also called tool use) allows a model to request external function execution during a conversation. The model returns a `tool_use` stop reason along with the function name and arguments. Your application executes the function locally and sends the result back to the model, which then generates a final response that incorporates the function output.
  - q: Which Bedrock models support function calling?
    a: |
      Cohere Command R and Command R+, Anthropic Claude 3 and later, and Amazon Titan models support function calling through the Converse API. Check the [AWS documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference-supported-models-features.html) for the full compatibility matrix.
  - q: Why does the script use dummy AWS credentials?
    a: |
      {{site.ai_gateway}} handles authentication with AWS Bedrock on behalf of the client (`auth.allow_override: false`). The Boto3 client still requires credentials to sign HTTP requests, but {{site.ai_gateway}} replaces them before forwarding to Bedrock. The dummy credentials never reach AWS.

automated_tests: false
---

## Configure the plugin

Configure AI Proxy Advanced to proxy native AWS Bedrock Converse API requests. The `llm_format: bedrock` setting tells Kong to accept native Bedrock API payloads and forward them to the correct Bedrock endpoint.

{% entity_examples %}
entities:
  plugins:
    - name: ai-proxy-advanced
      config:
        llm_format: bedrock
        targets:
        - route_type: llm/v1/chat
          auth:
            allow_override: false
            aws_access_key_id: ${aws_access_key_id}
            aws_secret_access_key: ${aws_secret_access_key}
          model:
            provider: bedrock
            name: cohere.command-r-v1:0
            options:
              bedrock:
                aws_region: ${aws_region}
variables:
  aws_access_key_id:
    value: $AWS_ACCESS_KEY_ID
  aws_secret_access_key:
    value: $AWS_SECRET_ACCESS_KEY
  aws_region:
    value: $AWS_REGION
{% endentity_examples %}

{:.info}
> The `config.llm_format: bedrock` setting enables Kong to accept native AWS Bedrock API requests. Kong detects the Converse API request pattern and routes it to the Bedrock Runtime service.

## Use AWS Bedrock function calling

The Bedrock Converse API supports function calling (tool use), which lets a model request execution of locally defined functions. The model doesn't execute functions directly. Instead, it returns a `tool_use` stop reason with the function name and input arguments. Your application runs the function and sends the result back to the model for a final response.

The following script defines a `top_song` tool that returns the most popular song for a given radio station call sign. The model receives a user question, decides to call the tool, and then incorporates the tool result into its final answer.

Create the script:

```sh
cat > bedrock-tool-use-demo.py << 'EOF'
#!/usr/bin/env python3
"""Demonstrate AWS Bedrock function calling (tool use) through Kong's AI Gateway"""

import logging
import json
import boto3
from botocore.exceptions import ClientError

GATEWAY_URL = "http://localhost:8000"

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)


class StationNotFoundError(Exception):
    """Raised when a radio station isn't found."""
    pass


def get_top_song(call_sign):
    """Returns the most popular song for the given radio station call sign."""
    if call_sign == "WZPZ":
        return "Elemental Hotel", "8 Storey Hike"
    raise StationNotFoundError(f"Station {call_sign} not found.")


def generate_text(bedrock_client, model_id, tool_config, input_text):
    """Sends a message to Bedrock and handles tool use if the model requests it."""

    logger.info("Sending request to model %s", model_id)

    messages = [{"role": "user", "content": [{"text": input_text}]}]

    response = bedrock_client.converse(
        modelId=model_id, messages=messages, toolConfig=tool_config
    )

    output_message = response["output"]["message"]
    messages.append(output_message)
    stop_reason = response["stopReason"]

    if stop_reason == "tool_use":
        tool_requests = output_message["content"]
        for tool_request in tool_requests:
            if "toolUse" not in tool_request:
                continue

            tool = tool_request["toolUse"]
            logger.info(
                "Model requested tool: %s (ID: %s)", tool["name"], tool["toolUseId"]
            )

            if tool["name"] == "top_song":
                try:
                    song, artist = get_top_song(tool["input"]["sign"])
                    tool_result = {
                        "toolUseId": tool["toolUseId"],
                        "content": [{"json": {"song": song, "artist": artist}}],
                    }
                except StationNotFoundError as err:
                    tool_result = {
                        "toolUseId": tool["toolUseId"],
                        "content": [{"text": err.args[0]}],
                        "status": "error",
                    }

                messages.append(
                    {"role": "user", "content": [{"toolResult": tool_result}]}
                )

                response = bedrock_client.converse(
                    modelId=model_id, messages=messages, toolConfig=tool_config
                )
                output_message = response["output"]["message"]

    for content in output_message["content"]:
        print(json.dumps(content, indent=4))


def main():
    model_id = "cohere.command-r-v1:0"
    input_text = "What is the most popular song on WZPZ?"

    tool_config = {
        "tools": [
            {
                "toolSpec": {
                    "name": "top_song",
                    "description": "Get the most popular song played on a radio station.",
                    "inputSchema": {
                        "json": {
                            "type": "object",
                            "properties": {
                                "sign": {
                                    "type": "string",
                                    "description": "The call sign for the radio station for which you want the most popular song. Example call signs are WZPZ and WKRP.",
                                }
                            },
                            "required": ["sign"],
                        }
                    },
                }
            }
        ]
    }

    bedrock_client = boto3.client(
        "bedrock-runtime",
        endpoint_url=GATEWAY_URL,
        region_name="us-west-2",
        aws_access_key_id="dummy",
        aws_secret_access_key="dummy",
    )

    try:
        print(f"Question: {input_text}")
        generate_text(bedrock_client, model_id, tool_config, input_text)
    except ClientError as err:
        message = err.response["Error"]["Message"]
        logger.error("A client error occurred: %s", message)
        print(f"A client error occurred: {message}")
    else:
        print(f"Finished generating text with model {model_id}.")


if __name__ == "__main__":
    main()
EOF
```

The script creates a Boto3 client pointed at the {{site.ai_gateway}} endpoint (`http://localhost:8000`) instead of directly at AWS. {{site.ai_gateway}} handles AWS authentication, so the client uses dummy credentials. The `allow_override: false` setting in the plugin configuration ensures that Kong always uses its own credentials, regardless of what the client sends.

The conversation flow works as follows:

1. The client sends the user question and tool definition to the model through Kong.
2. The model responds with a `tool_use` stop reason and the `top_song` function call with `{"sign": "WZPZ"}`.
3. The client executes `get_top_song("WZPZ")` locally and sends the result back to the model through Kong.
4. The model generates a final text response that incorporates the tool result.

## Validate the configuration

Run the script:

```sh
python3 bedrock-tool-use-demo.py
```

Expected output:

```text
INFO: Sending request to model cohere.command-r-v1:0
INFO: Model requested tool: top_song (ID: tooluse_abc123)
Question: What is the most popular song on WZPZ?
{
    "text": "The most popular song on WZPZ is \"Elemental Hotel\" by 8 Storey Hike."
}
Finished generating text with model cohere.command-r-v1:0.
```

The output confirms that {{site.ai_gateway}} correctly proxied both the initial Converse API request and the follow-up tool result message to AWS Bedrock. The model received the `top_song` tool output and generated a natural language response that includes the song title and artist.

If the request fails with authentication errors, verify that the `aws_access_key_id` and `aws_secret_access_key` in your Kong plugin configuration are valid and that the Cohere Command R model is enabled in your AWS Bedrock console.