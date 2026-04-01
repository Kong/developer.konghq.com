---
title: Stream AWS Bedrock function calling responses with AI Proxy Advanced
content_type: how_to
related_resources:
  - text: "{{site.ai_gateway}}"
    url: /ai-gateway/
  - text: AI Proxy Advanced
    url: /plugins/ai-proxy-advanced/
  - text: AWS Bedrock ConverseStream API
    url: https://docs.aws.amazon.com/bedrock/latest/APIReference/API_runtime_ConverseStream.html
  - text: Use AWS Bedrock function calling with AI Proxy Advanced
    url: /how-to/bedrock-function-calling/
breadcrumbs:
 - /ai-gateway/
permalink: /how-to/use-bedrock-function-calling-with-streaming/

description: "Configure the AI Proxy Advanced plugin to stream AWS Bedrock Converse API responses that include function calling."

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
  q: How do I stream Bedrock function calling responses through AI Proxy Advanced?
  a: |
    Use the same AI Proxy Advanced configuration as the non-streaming variant, with `llm_format: bedrock` and `llm/v1/chat` route type. In your client code, call `converse_stream` instead of `converse`. The streamed response delivers text chunks incrementally and includes tool use requests that your application handles before sending results back for a final streamed response.

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
    - title: Python and Boto3
      content: |
        Install Python 3 and the Boto3 SDK:
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
  - q: What is the difference between `converse` and `converse_stream`?
    a: |
      The `converse` method waits for the full model response before returning. The `converse_stream` method returns an event stream that delivers response chunks as they are generated. Streaming reduces perceived latency for the end user, since text appears incrementally rather than all at once. Both methods support function calling with the same tool configuration format.
  - q: Which Bedrock models support streaming with function calling?
    a: |
      Cohere Command R and Command R+, Anthropic Claude 3 and later, and Amazon Titan models support streaming function calling through the ConverseStream API. Check the [AWS documentation](https://docs.aws.amazon.com/bedrock/latest/userguide/conversation-inference-supported-models-features.html) for the full compatibility matrix.

automated_tests: false
---

## Configure the plugin

The plugin configuration for streaming is identical to non-streaming function calling. Configure AI Proxy Advanced to accept native AWS Bedrock API payloads. The `llm_format: bedrock` setting tells Kong to forward requests to the correct Bedrock endpoint, whether the client uses `converse` or `converse_stream`.

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
> The `config.llm_format: bedrock` setting enables Kong to accept native AWS Bedrock API requests. This configuration works for both `converse` and `converse_stream` calls without any changes.

## Stream Bedrock function calling responses

The Bedrock ConverseStream API delivers model output as a sequence of events rather than a single complete response. This is particularly useful for function calling, where the interaction involves multiple round trips. Text appears in the terminal as it is generated, and tool use requests arrive as streamed chunks that your application reassembles.

The following script defines a `top_song` tool and uses `converse_stream` to interact with the model. When the LLM model requests the tool, the script executes the function locally and then sends the result back through a second `converse_stream` call.

The stream delivers several event types: `messageStart` signals the beginning of a response, `contentBlockStart` and `contentBlockDelta` carry tool use or text data in fragments, `contentBlockStop` marks the end of a content block, and `messageStop` provides the stop reason.

Create the script:

```sh
cat > bedrock-stream-tool-use-demo.py << 'EOF'
#!/usr/bin/env python3
"""Demonstrate streaming function calling through Kong's AI Gateway"""

import logging
import json
import boto3

from botocore.exceptions import ClientError

GATEWAY_URL = "http://localhost:8000"

logger = logging.getLogger(__name__)
logging.basicConfig(level=logging.INFO)


class StationNotFoundError(Exception):
    """Raised when a radio station isn't found."""
    pass


def get_top_song(call_sign):
    """Returns the most popular song for the given radio station call sign."""
    if call_sign == 'WZPZ':
        return "Elemental Hotel", "8 Storey Hike"
    raise StationNotFoundError(f"Station {call_sign} not found.")


def stream_messages(bedrock_client, model_id, messages, tool_config):
    """Sends a message and processes the streamed response.

    Reassembles text and tool use content from stream events.
    Text chunks are printed to stdout as they arrive.

    Returns:
        stop_reason: The reason the model stopped generating.
        message: The fully reassembled response message.
    """

    logger.info("Streaming messages with model %s", model_id)

    response = bedrock_client.converse_stream(
        modelId=model_id,
        messages=messages,
        toolConfig=tool_config
    )

    stop_reason = ""
    message = {}
    content = []
    message['content'] = content
    text = ''
    tool_use = {}

    for chunk in response['stream']:
        if 'messageStart' in chunk:
            message['role'] = chunk['messageStart']['role']
        elif 'contentBlockStart' in chunk:
            tool = chunk['contentBlockStart']['start']['toolUse']
            tool_use['toolUseId'] = tool['toolUseId']
            tool_use['name'] = tool['name']
        elif 'contentBlockDelta' in chunk:
            delta = chunk['contentBlockDelta']['delta']
            if 'toolUse' in delta:
                if 'input' not in tool_use:
                    tool_use['input'] = ''
                tool_use['input'] += delta['toolUse']['input']
            elif 'text' in delta:
                text += delta['text']
                print(delta['text'], end='')
        elif 'contentBlockStop' in chunk:
            if 'input' in tool_use:
                tool_use['input'] = json.loads(tool_use['input'])
                content.append({'toolUse': tool_use})
                tool_use = {}
            else:
                content.append({'text': text})
                text = ''
        elif 'messageStop' in chunk:
            stop_reason = chunk['messageStop']['stopReason']

    return stop_reason, message


def main():
    logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")

    model_id = "cohere.command-r-v1:0"
    input_text = "What is the most popular song on WZPZ?"

    try:
        bedrock_client = boto3.client(
            "bedrock-runtime",
            region_name="us-west-2",
            endpoint_url=GATEWAY_URL,
            aws_access_key_id="dummy",
            aws_secret_access_key="dummy",
        )

        messages = [{"role": "user", "content": [{"text": input_text}]}]

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
                                        "description": "The call sign for the radio station for which you want the most popular song. Example call signs are WZPZ and WKRP."
                                    }
                                },
                                "required": ["sign"]
                            }
                        }
                    }
                }
            ]
        }

        stop_reason, message = stream_messages(
            bedrock_client, model_id, messages, tool_config)
        messages.append(message)

        if stop_reason == "tool_use":
            for block in message['content']:
                if 'toolUse' in block:
                    tool = block['toolUse']

                    if tool['name'] == 'top_song':
                        try:
                            song, artist = get_top_song(tool['input']['sign'])
                            tool_result = {
                                "toolUseId": tool['toolUseId'],
                                "content": [{"json": {"song": song, "artist": artist}}]
                            }
                        except StationNotFoundError as err:
                            tool_result = {
                                "toolUseId": tool['toolUseId'],
                                "content": [{"text": err.args[0]}],
                                "status": 'error'
                            }

                        messages.append({
                            "role": "user",
                            "content": [{"toolResult": tool_result}]
                        })

            stop_reason, message = stream_messages(
                bedrock_client, model_id, messages, tool_config)

    except ClientError as err:
        message = err.response['Error']['Message']
        logger.error("A client error occurred: %s", message)
        print(f"A client error occurred: {message}")
    else:
        print(f"\nFinished streaming messages with model {model_id}.")


if __name__ == "__main__":
    main()
EOF
```

The script points a Boto3 client at the {{site.ai_gateway}} route (`http://localhost:8000`) with dummy credentials. {{site.ai_gateway}} replaces these credentials with the real AWS keys from the plugin configuration before forwarding to Bedrock.

The interaction follows two streaming rounds:

1. The first `converse_stream` call sends the user question and tool definition. The model responds with a stream that contains a tool use request, delivering the function name (`top_song`) and input arguments (`{"sign": "WZPZ"}`) across multiple `contentBlockDelta` events. The script reassembles these fragments into a complete tool call.
2. The script executes `get_top_song("WZPZ")` locally and appends the result to the message history. A second `converse_stream` call sends the full conversation, including the tool result. The model streams its final answer, with each text chunk printed to the terminal as it arrives.

## Validate the configuration

Run the script:

```sh
python3 bedrock-stream-tool-use-demo.py
```

Expected output:

```text
INFO:__main__:Streaming messages with model cohere.command-r-v1:0
INFO:__main__:Streaming messages with model cohere.command-r-v1:0
I will search for the most popular song on WZPZ and relay this information to the user.The most popular song on WZPZ is Elemental Hotel by 8 Storey Hike.
Finished streaming messages with model cohere.command-r-v1:0.
```

The `INFO` line appears twice because the script makes two `converse_stream` calls: one for the initial request (which results in a tool use), and one after sending the tool result back. The final text response streams to the terminal as it is generated.

If the request fails with authentication errors, confirm that the `aws_access_key_id` and `aws_secret_access_key` in your plugin configuration are valid and that the Cohere Command R model is enabled in your AWS Bedrock console.