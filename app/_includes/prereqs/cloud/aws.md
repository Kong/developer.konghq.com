{%- assign summary='AWS configuration' -%}
{%- capture details_content -%}
{% if config.secret %}
This tutorial requires at least one [secret](https://docs.aws.amazon.com/secretsmanager/latest/userguide/create_secret.html) in AWS Secrets Manager. In this example, the secret is named `my-aws-secret` and contains a key/value pair in which the key is `token`.
{% endif %}

You will also need the following authentication information to connect your AWS Secrets Manager with {{site.ee_product_name}}:
- Your access key ID
- Your secret access key
- Your session token
- Your AWS region, `us-east-1` in this example

```sh
export AWS_ACCESS_KEY_ID='YOUR AWS ACCESS KEY ID'
export AWS_SECRET_ACCESS_KEY='YOUR AWS SECRET ACCESS KEY'
```

{:.warning}
> If you get an error stating "The security token included in the request is invalid", you need to set the `AWS_SESSION_TOKEN` environment variable.

{% if include.products contains 'kic' %}
Note that these variables need to be provided in `customEnv` in your `values.yaml` file below too
{% else %}
Note that these variables need to be passed when creating your Data Plane container.
{% endif %}

Alternative connection methods such as `assume role` and how to use an `aws_session_token` can be found on the [AWS Secrets Manager page](/gateway/entities/vault/?tab=aws#vault-provider-specific-configuration-parameters)
{% endcapture %}

{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url='/assets/icons/aws.svg' %}