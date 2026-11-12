{% include_cached components/plugin_credential_example/lead_sentence.md plugin_name=include.presenter.plugin_name %}

Create the Consumer:

{% include components/entity_example/format/snippets/admin-api.md presenter=include.presenter.consumer_request %}

Attach the `{{ include.presenter.credential.endpoint }}` credential:

{% include components/entity_example/format/snippets/admin-api.md presenter=include.presenter.credential_request %}
