{%- assign mb = site.data.plugins["metering-and-billing"] -%}
{% for event in mb.events %}
#### `{{ event.type }}`

{{ event.when }}

{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
{% for f in event.fields %}
  - field: "`{{ f.field }}`"
    type: "{{ f.type }}"
    description: "{{ f.description }}"
{% endfor %}
{% endtable %}
{% endfor %}
#### Portal and application fields

The following fields are included only when the request is associated with a {{ site.konnect_short_name }} Dev Portal application or API product, and can appear on either event type.

{% table %}
columns:
  - title: Field
    key: field
  - title: Type
    key: type
  - title: Description
    key: description
rows:
{% for f in mb.portal_fields %}
  - field: "`{{ f.field }}`"
    type: "{{ f.type }}"
    description: "{{ f.description }}"
{% endfor %}
{% endtable %}
