For cross-region inference, prefix the model ID with a geographic identifier:

```
{geography-prefix}.{provider}.{model-name}...
```

For example: `us.anthropic.claude-sonnet-4-5-20250929-v1:0`

{% table %}
columns:
    - title: Prefix
      key: prefix
    - title: Geography
      key: geography
rows:
    - prefix: "`us.`"
      geography: "United States"
    - prefix: "`eu.`"
      geography: "European Union"
    - prefix: "`apac.`"
      geography: "Asia-Pacific"
    - prefix: "`global.`"
      geography: "All commercial regions"
{% endtable %}

For a full list of supported cross-region inference profiles, see [Supported Regions and models for inference profiles](https://docs.aws.amazon.com/bedrock/latest/userguide/inference-profiles-support.html) in the AWS documentation.