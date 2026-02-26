{% for field in config.fields %}
{% for i in (1..heading_level) %}#{% endfor %} Parameter: {{field.name}}
parameter: {{field.name}}
default_value: {% if field.default_value != nil %}{% assign default_value = field.default_value %}{% if field.array? %}{% assign default_value = field.default_value | join: ', ' %}{% endif %}{{default_value}}{% else %}none{% endif %}
description: |
{{field.description | indent: 2}}
{% endfor %}