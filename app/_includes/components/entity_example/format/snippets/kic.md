{% if include.presenter.custom_template %}
{% include {{ include.presenter.custom_template }} presenter=include.presenter %}
{% else %}

```yaml
{{ include.presenter }}
```
{% endif %}

{% if include.presenter.entity_type == "plugin" and include.presenter.foreign_keys.size > 0 %}
Next, apply the `KongPlugin` resource by annotating the {{ include.presenter.targets }}:

```bash
{% for key in include.presenter.foreign_keys -%}
kubectl annotate {% if key == "Service" %}service{% elsif key == "Route" %}ingress{% else %}Kong{{ key }}{% endif %} {{ key | upcase}}_NAME konghq.com/plugins={{ include.presenter.data.name }}
{% endfor -%}
```

{:.note}
> Note: The `KongPlugin` resource only needs to be defined once and can be applied to any service, consumer, consumer group, or route in the namespace. If you want the plugin to be available cluster-wide, create the resource as a `KongClusterPlugin` instead of `KongPlugin`.

{% endif %}
