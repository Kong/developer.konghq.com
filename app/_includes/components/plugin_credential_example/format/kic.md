{% include_cached components/plugin_credential_example/lead_sentence.md plugin_name=include.presenter.plugin_name %}

Create a `Secret` labeled with the `{{ include.presenter.credential.endpoint }}` credential type:

```yaml
apiVersion: v1
kind: Secret
metadata:
  name: {{ include.presenter.secret_name }}
  namespace: kong
  labels:
    konghq.com/credential: {{ include.presenter.credential.endpoint }}
stringData:
{% for pair in include.presenter.credential.data %}  {{ pair[0] }}: {{ pair[1] }}
{% endfor -%}
```

Create the `KongConsumer` and reference the `Secret`:

```yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumer
metadata:
  name: {{ include.presenter.consumer.username }}
  namespace: kong
  annotations:
    kubernetes.io/ingress.class: kong
username: {{ include.presenter.consumer.username }}
credentials:
- {{ include.presenter.secret_name }}
```
