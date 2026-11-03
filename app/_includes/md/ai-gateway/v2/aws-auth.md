## Authentication with AWS

For {{ provider.name }}, you can also set `auth` to `aws`. Provide static IAM user credentials with `access_key_id` and `secret_access_key`, or omit them to fall back to the default AWS credentials provider chain (EC2 instance profiles, environment variables, and so on). For cross-account access, assume a role with `assume_role_arn` and `role_session_name`.

See [Outbound authentication](/ai-gateway/entities/ai-model-provider/#outbound-authentication) on the AI Model Provider entity page for the full list of `auth` fields, including `sts_endpoint_url` and the Bedrock-specific `batch_role_arn`.

{:.info}
> **AWS Session tokens**
>
> There's no dedicated field for an AWS session token.
> For temporary credentials, set `config.auth.assume_role_arn` and `config.auth.role_session_name` to assume a role through AWS STS, or leave `config.auth.access_key_id` and `config.auth.secret_access_key` unset to fall back to environment variables or an instance or task IAM role.

{% new_in 2.4 %}

### Service name and host inference

By default, the AWS service name and region used in the SigV4 signature are inferred from the host of the signed request. For example, `abc123.execute-api.us-east-1.amazonaws.com` yields the service `execute-api` in the region `us-east-1`.

Set `service` to override the inferred service name, such as `execute-api` for Amazon API Gateway or `lambda` for Lambda function URLs. Set it when the upstream is reached through a host that doesn't follow the `<service>.<region>.amazonaws.com` pattern, such as an Amazon API Gateway custom domain name. For hosts that don't contain a region, also set `region`.
