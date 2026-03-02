---
title: 'AWS Lambda'
name: 'AWS Lambda'

content_type: plugin

publisher: kong-inc
description: 'Invoke and manage AWS Lambda functions from {{site.base_gateway}}'

tags:
  - serverless
  - aws

products:
    - gateway

works_on:
    - on-prem
    - konnect


topologies:
  on_prem:
    - hybrid
    - db-less
    - traditional
  konnect_deployments:
    - hybrid
    - cloud-gateways
    - serverless

icon: aws-lambda.png

categories:
  - serverless

search_aliases:
  - AWS Lambda

notes: |
  **Dedicated Cloud Gateways**: If you use the IAM assumeRole functionality with this plugin, 
  it must be configured differently than for hybrid deployments in Konnect.

min_version:
  gateway: '1.0'
---

This plugin lets you invoke an [AWS Lambda](https://aws.amazon.com/lambda/) function from {{site.base_gateway}}. 
The AWS Lambda plugin can be used in combination with other [request plugins](/plugins/?terms=request) 
to secure, manage, or extend the function.

Any form parameter sent along with the request is also sent as an argument to the AWS Lambda function.


## AWS authentication

The AWS Lambda plugin will automatically fetch the IAM role credential according to the following
precedence order:
1. Fetch from the credentials defined in the [`config.aws_key`](./reference/#schema--config-aws_key) and [`config.aws_secret`](./reference/#schema--config-aws_secret) parameters in the plugin configuration.

   {:.info}
   > By default, cURL sends payloads with an
   `application/x-www-form-urlencoded` MIME type, which will naturally be URL-decoded by {{site.base_gateway}}. 
   To ensure special characters that are likely to appear in
   your AWS key or secret (like `+`) are correctly decoded, you must
   URL-encode them with `--data-urlencode`.
   Alternatives to this approach would be to send your payload with a
   different MIME type (like `application/json`), or to use a different HTTP client.

1. Fetch from the credentials defined in the `AWS_ACCESS_KEY_ID` and `AWS_SECRET_ACCESS_KEY` environment variables.
1. Fetch from the profile and credential file, defined by `AWS_PROFILE` and `AWS_SHARED_CREDENTIALS_FILE`.
1. Fetch from the ECS [container credential provider](https://docs.aws.amazon.com/sdkref/latest/guide/feature-container-credentials.html).
1. Fetch from the EKS [IAM roles for the service account](https://docs.aws.amazon.com/eks/latest/userguide/iam-roles-for-service-accounts.html).
1. Fetch from the EC2 IMDS metadata. Both v1 and v2 are supported.

{:.info}
> **Note:** IAM Identity Center credential provider and Process credential provider are not supported.

If you also specify the [`config.aws_assume_role_arn`](./reference/#schema--config-aws_assume_role_arn) parameter, the plugin will try to perform
an additional [AssumeRole](https://docs.aws.amazon.com/STS/latest/APIReference/API_AssumeRole.html)
action. This requires the {{site.base_gateway}} process to make an HTTPS request to the AWS STS service API after
configuring the AWS access key/secret or fetching credentials automatically from EC2/ECS/EKS IAM roles.
If it succeeds, the plugin will fetch temporary security credentials that give the plugin the access permission configured in the target assumed role. The plugin will then try to invoke the Lambda function based on the target assumed role.

## AWS region

If the [`config.aws_region`](./reference/#schema--config-aws_region) parameter isn't specified, the plugin attempts to get the
AWS region through the environment variables `AWS_REGION` and `AWS_DEFAULT_REGION`,
in that order. If none of these are set, a runtime error `no region or host specified`
will be thrown.
