{% include_cached components/plugin_credential_example/lead_sentence.md plugin_name=include.presenter.plugin_name %}

The following creates the Consumer and attaches the credential in one document:

```yaml
_format_version: "3.0"
{{ include.presenter.config }}
```
{: data-file="kong.yaml" data-tool="deck" }
