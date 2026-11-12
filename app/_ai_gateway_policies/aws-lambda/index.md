---
min_version:
  ai-gateway: '2.0'
works_on:
  - on-prem
  - konnect
products:
  - ai-gateway
content_type: plugin
tools:
  - konnect-api
  - kongctl
description: Invoke and manage AWS Lambda functions from {{site.ai_gateway_name}}
categories:
  - serverless
tags:
  - serverless
  - aws
search_aliases:
  - AWS Lambda
related_resources:
  - text: AI Policy entity
    url: /ai-gateway/entities/ai-policy/
  - text: AI Model entity
    url: /ai-gateway/entities/ai-model/
  - text: AI Agent entity
    url: /ai-gateway/entities/ai-agent/
  - text: AI MCP Server entity
    url: /ai-gateway/entities/ai-mcp-server/
---

The AWS Lambda [AI Policy](/ai-gateway/entities/ai-policy/) invokes an [AWS Lambda](https://aws.amazon.com/lambda/) function from {{site.ai_gateway}}.
Instead of forwarding a request to an upstream, the policy sends the request to your Lambda function and returns the function's response to the client.
Use it to expose an existing Lambda function through a {{site.ai_gateway}} endpoint, so clients call one address and the function stays behind the gateway.

## How does the AWS Lambda Policy work?

When a request reaches an entity that has the policy attached, the policy calls the Lambda Invoke API for the function in [`config.function_name`](/ai-gateway/policies/aws-lambda/reference/#schema--config-function-name).
The policy accepts a function name or an ARN, including a partial ARN.
Use [`config.qualifier`](/ai-gateway/policies/aws-lambda/reference/#schema--config-qualifier) to invoke a specific function version or alias.

The policy returns the function's response to the client.
The entity that the policy is attached to sends no request to its upstream.

The following example invokes a Lambda function and waits for the response:

{% entity_example %}
type: policy
data:
  name: aws-lambda-invoke
  display_name: Invoke AWS Lambda Function
  type: aws-lambda
  config:
    aws_key: $AWS_KEY
    aws_secret: $AWS_SECRET
    aws_region: $AWS_REGION
    function_name: $LAMBDA_FUNCTION
    invocation_type: RequestResponse
formats:
  - konnect-api
{% endentity_example %}

### Choose what the function receives

By default, the policy sends the function a flat JSON object that merges the query string arguments and the parsed request body arguments.

When you set any of the `forward_request_*` parameters to `true`, the policy sends a structured JSON object that contains only the fields you enable:

{% table %}
columns:
  - title: Parameter
    key: parameter
  - title: Field added to the payload
    key: field
  - title: Notes
    key: notes
  - title: Example value in the payload
    key: example
rows:
  - parameter: "[`config.forward_request_method`](/ai-gateway/policies/aws-lambda/reference/#schema--config-forward-request-method)"
    field: "`request_method`"
    notes: "The HTTP method of the request."
    example: '`"request_method": "POST"`'
  - parameter: "[`config.forward_request_uri`](/ai-gateway/policies/aws-lambda/reference/#schema--config-forward-request-uri)"
    field: "`request_uri` and `request_uri_args`"
    notes: "The request path with its query string, and the parsed query arguments."
    example: '`"request_uri": "/support/chat/completions?status=open"` and `"request_uri_args": {"status": "open"}`'
  - parameter: "[`config.forward_request_headers`](/ai-gateway/policies/aws-lambda/reference/#schema--config-forward-request-headers)"
    field: "`request_headers`"
    notes: "A map of the request headers."
    example: '`"request_headers": {"content-type": "application/json"}`'
  - parameter: "[`config.forward_request_body`](/ai-gateway/policies/aws-lambda/reference/#schema--config-forward-request-body)"
    field: "`request_body` and `request_body_args`"
    notes: "The raw body and the parsed body arguments. When the content type is unknown and [`config.base64_encode_body`](/ai-gateway/policies/aws-lambda/reference/#schema--config-base64-encode-body) is `true`, the policy Base64-encodes `request_body` and adds `request_body_base64`."
    example: '`"request_body_args": {"stream": false, "messages": [...]}`'
{% endtable %}

The following example sends the function the request method, the request URI, and the request body:

{% entity_example %}
type: policy
data:
  name: aws-lambda-structured-payload
  display_name: Invoke AWS Lambda Function with a structured payload
  type: aws-lambda
  config:
    aws_key: $AWS_KEY
    aws_secret: $AWS_SECRET
    aws_region: $AWS_REGION
    function_name: $LAMBDA_FUNCTION
    forward_request_method: true
    forward_request_uri: true
    forward_request_body: true
formats:
  - konnect-api
  - kongctl
{% endentity_example %}

With this configuration, the policy is attached to an AI Model that has the route path `/support` and the model name `support-model`. A `POST` request to `/support/chat/completions?status=open` with the following body reaches the function as the payload that follows:

```json
{
  "model": "support-model",
  "messages": [
    {
      "role": "user",
      "content": "order 42"
    }
  ]
}
```

```json
{
  "request_method": "POST",
  "request_uri": "/support/chat/completions?status=open",
  "request_uri_args": {
    "status": "open"
  },
  "request_body": "{\"messages\":[{\"content\":\"order 42\",\"role\":\"user\"}],\"stream\":false,\"model\":\"<provider-model-name>\"}",
  "request_body_args": {
    "stream": false,
    "messages": [
      {
        "content": "order 42",
        "role": "user"
      }
    ],
    "model": "<provider-model-name>"
  }
}
```

The `model` field holds the provider model name from the AI Model target, not `support-model`, because {{site.ai_gateway}} rewrites the body before the policy runs. {{site.ai_gateway}} also adds `stream`. The payload has no `request_headers` field, because `config.forward_request_headers` isn't enabled.

{:.success}
> Set [`config.awsgateway_compatible`](/ai-gateway/policies/aws-lambda/reference/#schema--config-awsgateway-compatible) to `true` to send an Amazon API Gateway payload instead.
> This setting takes precedence over the `forward_request_*` parameters, and [`config.awsgateway_compatible_payload_version`](/ai-gateway/policies/aws-lambda/reference/#schema--config-awsgateway-compatible-payload-version) selects version `1.0` or `2.0`.
>
> Set [`config.is_proxy_integration`](/ai-gateway/policies/aws-lambda/reference/#schema--config-is-proxy-integration) to `true` when your function returns a Lambda proxy integration response.
> The policy reads `statusCode`, `headers`, and `body` from the function's JSON response and returns them to the client.
> When the response isn't valid JSON, clients receive a `502` response.

### Choose an invocation type

Set [`config.invocation_type`](/ai-gateway/policies/aws-lambda/reference/#schema--config-invocation-type) to `RequestResponse` when the client needs the function's result.
Set it to `Event` to run the function asynchronously and return without its result.
Set it to `DryRun` to validate the call and the caller's permissions without running the function.

## AWS authentication

The AWS Lambda Policy fetches the AWS credentials in the following order:

1. The credentials in the [`config.aws_key`](/ai-gateway/policies/aws-lambda/reference/#schema--config-aws-key) and [`config.aws_secret`](/ai-gateway/policies/aws-lambda/reference/#schema--config-aws-secret) parameters.
1. The `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables on the data plane.
1. The profile and credential file defined by `AWS_PROFILE` and `AWS_SHARED_CREDENTIALS_FILE`.
1. The ECS [container credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html).
1. The EKS [IAM roles for the service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).
1. The EC2 instance metadata service (IMDS).
   The policy supports v1 and v2, and [`config.aws_imds_protocol_version`](/ai-gateway/policies/aws-lambda/reference/#schema--config-aws-imds-protocol-version) selects the version.

The policy doesn't support the IAM Identity Center credential provider or the Process credential provider.

If you also set [`config.aws_assume_role_arn`](/ai-gateway/policies/aws-lambda/reference/#schema--config-aws-assume-role-arn), the policy performs an additional [AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html) action.
The data plane makes an HTTPS request to the AWS STS API with the configured or fetched credentials.
The policy then invokes the Lambda function with the temporary credentials of the assumed role.

Store `config.aws_key`, `config.aws_secret`, and `config.aws_assume_role_arn` as secret references to an [AI Vault](/ai-gateway/entities/ai-vault/).
If you set a literal value instead, Konnect returns it as plain text in API responses.

## AWS region

If you don't set [`config.aws_region`](/ai-gateway/policies/aws-lambda/reference/#schema--config-aws-region), the policy reads the region from the `AWS_REGION` environment variable, and then from `AWS_DEFAULT_REGION`.
If neither variable is set, the policy fails with the error `no region or host specified`.

## Use the policy in {{site.ai_gateway}}

The AWS Lambda Policy attaches to an [AI Model](/ai-gateway/entities/ai-model/), [AI Agent](/ai-gateway/entities/ai-agent/), or [AI MCP Server](/ai-gateway/entities/ai-mcp-server/), because {{site.ai_gateway}} has no Gateway Services or Routes.
The entity provides the route that clients call, and the policy answers the request.
For details about how scopes work, see [AI Policy scopes](/ai-gateway/entities/ai-policy/#ai-policy-scopes).

* **The upstream receives no traffic:** The policy answers the request itself.
  An AI Model still requires an [AI Model Provider](/ai-gateway/entities/ai-model-provider/) target, and clients must still send the `model` field that the AI Model route matches on.
  {{site.ai_gateway}} doesn't send the request to the provider.
* **{{site.ai_gateway}} changes the request body first:** Before the policy runs, {{site.ai_gateway}} processes the request for the AI Model.
  For example, the `model` field in the body becomes the provider model name configured on the target, so the function receives that value instead of the AI Model name.
* **Scope:** Attach the policy to an AI Model, AI Agent, or AI MCP Server.
  The policy doesn't support [AI Consumer Group](/ai-gateway/entities/ai-consumer-group/) scope.
* **Errors:** When the Lambda Invoke API rejects a call, for example because the function doesn't exist or the credentials are invalid, clients receive a `500` response with the message `An unexpected error occurred`.
  The cause appears in the data plane log.

{:.warning}
> Don't apply the AWS Lambda Policy globally.
> A global policy answers every request on the data plane, so no other AI Model, AI Agent, or AI MCP Server receives traffic.
