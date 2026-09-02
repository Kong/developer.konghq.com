---
title: "{{site.base_gateway}}: How to configure AWS Lambda plugin when doing cross-account function invocation"
content_type: support
description: "Covers the AWS IAM role and `aws-lambda` plugin misconfigurations that cause cross-account AWS Lambda invocation errors in {{site.base_gateway}}, and how to correctly set up role assumption using the `aws_assume_role_arn` field."
products:
  - gateway
works_on:
  - on-prem
  - konnect
related_resources:
  - text: aws-lambda plugin configuration
    url: /plugins/aws-lambda/
tldr:
  q: Why does the aws-lambda plugin fail to invoke a Lambda function in another AWS account?
  a: |
    Cross-account Lambda invocation with the `aws-lambda` plugin requires an IAM role in the target account that trusts the calling account, with the calling account's IAM user or role allowed to assume it. In {{site.base_gateway}}, set the ARN of that role in the plugin's `aws_assume_role_arn` field — omitting it, or granting permissions directly to the IAM user instead of using role assumption, produces `not authorized to perform: lambda:InvokeFunction` or `Cross-account log access is not allowed` errors.
---

## Problem

I configured IAM permission policies to allow one AWS IAM user to invoke a lambda function which is owned by another AWS account, after applied the AWS Lambda plugin in {{site.base_gateway}}, I see errors like below:

```

[aws-lambda] User: arn:aws:iam::851725256956:user/sk2 is not authorized to pe
rform: lambda:InvokeFunction on resource: arn:aws:lambda:us-east-2:851725256956:function:sgao_test_func because no identity-based policy allows the lambda:InvokeFunction action, client: 10.0.0.1, server: kong, request: "GET /lambda HTTP/1.1", host: "localhost:8000", request_id: "f472d3038ca6f260129d74215c5cdd16"
```

Note: this happens when correct AWS IAM permission policies and assumeRole permissions are in place, but missing the `Aws Assume Role Arn` value in the AWS Lambda plugin

Or

```

2024/03/21 14:30:44 [error] 2188#0: *1477941 [kong] init.lua:351 [aws-lambda] {"Message":"Cross-account log access is not allowed"}, client: 10.51.210.234, server: kong, request: "GET /platform/v1/download?id=3535345345 HTTP/1.1", host: "api.us.dev.contoso.cloud"}
```

Note: this could happen when grant permissions directly to the IAM user in the other AWS account to invoke lambda functions in the target AWS account. However, this approach may increase the complexity of managing permissions across accounts, and it's generally considered a better practice to use role assumption for cross-account access whenever possible.

## Solution

The core issue revolves around the AWS IAM role/permission policy and the `aws-lambda` plugin configuration in {{site.base_gateway}}, specifically when attempting to invoke an AWS Lambda function across different AWS accounts.

The above errors are most likely related to misconfiguration on AWS and Kong's `aws-lambda` plugin.

To resolve this issue, follow these steps:

1. **Cross-Account Lambda Function Invocation Setup:**

In the AWS account owning the Lambda function:

- Create an IAM Role that grants the necessary permissions for invoking Lambda functions. This role will be assumed by IAM users from another AWS account.

- Define a trust relationship with the other AWS account, allowing IAM users from that account to assume the role.

- Attach policies to the IAM role that grant permissions to invoke Lambda functions.

In the other AWS account (the one used by the `aws-lambda` plugin):

- Create an IAM user who will be invoking Lambda functions in the above AWS account.

- Attach a policy to the IAM user that allows assuming the IAM role created in the above account.

2. **{{site.base_gateway}} `aws-lambda` Plugin Configuration:**

Ensure that the role ARN is added into the `aws-lambda` plugin configuration. This is crucial for cross-account Lambda function invocation. The relevant field in the plugin configuration is `aws_assume_role_arn`.

Here is an example snippet of the `aws-lambda` plugin configuration with the `aws_assume_role_arn` field:

```json

{
"config": {
"function_name": "arn:aws:lambda:us-east-1:123456789012:function:your-function-name",
"aws_region": "us-east-1",
"aws_key": "your-aws-access-key",
"aws_secret": "your-aws-secret-key",
"aws_assume_role_arn": "arn:aws:iam::123456789012:role/your-assume-role",
"invocation_type": "RequestResponse",
"log_type": "Tail",
"timeout": 60000,
"forward_request_headers": true
}
}
```

Ensure that the `aws_assume_role_arn` field is correctly set with the ARN of the IAM role created for cross-account access.

3. **Additional Tips:**

- For logging purposes, if you encounter issues with logs not appearing when using the `aws-lambda` plugin, consider adjusting the `log_type` configuration based on your requirements for security monitoring and troubleshooting.

By following these steps, you should be able to configure the `aws-lambda` plugin in {{site.base_gateway}} for successful cross-account Lambda function invocation.
