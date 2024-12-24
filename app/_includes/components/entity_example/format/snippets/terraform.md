{% if include.presenter.entity_type == "plugin" %}
{% assign plugin_name = include.presenter.data.name | replace: "-","_" %}
```hcl
resource "{{ include.presenter.resource_name }}_{{ plugin_name }}" "my_{{ plugin_name }}" {
  enabled = true

  {{ include.presenter }}
  control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id{% if include.presenter.target %}
  {{ include.presenter.target }} = {
    id = konnect_gateway_{{ include.presenter.target }}.my_{{ include.presenter.target }}.id
  }
{%- endif %}
}
```
{% elsif include.presenter.entity_type == "target" %}
```hcl
resource "{{ include.presenter.resource_name }}" "my_{{ include.presenter.entity_type }}" {
  {{ include.presenter }}
  upstream_id = konnect_gateway_upstream.my_upstream.id
  control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
}
```
{% else %}
```hcl
resource "{{ include.presenter.resource_name }}" "my_{{ include.presenter.entity_type }}" {
  {{ include.presenter }}
  control_plane_id = konnect_gateway_control_plane.my_konnect_cp.id
}
```
{% endif %}
