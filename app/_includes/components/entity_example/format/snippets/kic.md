{% if include.presenter.custom_template %}
{% include {{ include.presenter.custom_template }} presenter=include.presenter %}
{% else %}

```yaml
echo "
{{ include.presenter }}
" | kubectl apply -f -
```
{% endif %}

{% if include.presenter.entity_type == "plugin" and include.presenter.foreign_keys.size > 0 %}
{% unless include.presenter.skip_annotate %}
Next, apply the `KongPlugin` resource by annotating the {{ include.presenter.targets }}:

{% if include.presenter.foreign_keys[0] != "Route" %}
```bash
{% for key in include.presenter.foreign_keys -%}
{% capture target_name %}{{ key | upcase }}_NAME{% endcapture -%}
{% if include.presenter.foreign_key_names[key] %}{% assign target_name = include.presenter.foreign_key_names[key] %}{% endif -%}
kubectl annotate -n kong {% if key contains "Service" %}{{ key | downcase }}{% else %}{% if key contains "Route" %}{{ key | downcase }}{% endif %}{% if key == "Kongroute" %}{{ key | downcase }}{% endif %}{% if key == "Kongservice" %}{{ key | downcase }}{% endif %}{% if key contains "Consumer" %}kong{{ key | downcase }}{% endif %}{% else %}Kong{{ key }}{% endif %} {{ target_name }} konghq.com/plugins={{ include.presenter.other_plugins }}{{ include.presenter.full_resource.metadata.name }}{% if include.presenter.other_plugins %} --overwrite{% endif %}
{% endfor -%}
```
{% else %}
{% navtabs api %}
{% navtab "Gateway API" %}
```bash
kubectl annotate -n kong httproute {{ include.presenter.foreign_key_names['Route'] }} konghq.com/plugins={{ include.presenter.other_plugins }}{{ include.presenter.full_resource.metadata.name }}
```
{% endnavtab %}
{% navtab "Ingress" %}
```bash
kubectl annotate -n kong ingress {{ include.presenter.foreign_key_names['Route'] }} konghq.com/plugins={{ include.presenter.other_plugins }}{{ include.presenter.full_resource.metadata.name }}
```
{% endnavtab %}
{% endnavtabs %}
{% endif %}
{% endunless %}

{% endif %}
