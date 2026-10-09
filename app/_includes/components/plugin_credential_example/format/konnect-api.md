{% include_cached components/plugin_credential_example/lead_sentence.md plugin_name=include.presenter.plugin_name %}

Create the Consumer:

{% include components/entity_example/format/snippets/konnect-api.md presenter=include.presenter.consumer_request %}

Attach the `{{ include.presenter.credential.endpoint }}` credential:

{% include components/entity_example/format/snippets/konnect-api.md presenter=include.presenter.credential_request %}

{% include components/entity_example/replace_variables.md missing_variables=include.presenter.missing_variables %}
See the [Konnect Control Planes Config API reference](/api/konnect/control-planes-config/) to learn about region-specific URLs and personal access tokens.
