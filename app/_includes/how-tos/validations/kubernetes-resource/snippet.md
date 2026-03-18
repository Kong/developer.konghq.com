{%- assign name = include.config.name -%}
{%- assign kind = include.config.kind -%}
{%- assign conditionType = include.config.conditionType | default: "Programmed" -%}
{%- assign reason = include.config.reason | default: "Programmed" -%}
{%- assign generation = include.config.generation | default: 1 -%}
{%- unless include.config.disableDescription %}
You can verify the `{{ kind }}` was reconciled successfully by checking its `{{ conditionType }}` condition.
{% endunless %}

```bash
kubectl get {% if include.config.namespace %}-n {{ include.config.namespace }} {% endif %}{{ kind | downcase }} {{ name }} \
  -o=jsonpath='{.status.conditions[?(@.type=="{{ conditionType }}")]}' | jq
```

The output should look similar to this:

```json
{
  "observedGeneration": {{ generation }},
  "reason": "{{ reason }}",
  "status": "True",
  "type": "{{ conditionType }}"
}
```
