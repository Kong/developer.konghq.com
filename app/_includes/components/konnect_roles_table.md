{% for role_hash in config.roles %}{% assign role = role_hash[1] %}
{% for i in (1..heading_level) %}#{% endfor %} Role: {{role.properties.name.enum | first}}
role: {{role.properties.name.enum | first}}
description: |
{{role.properties.description.enum | first  | indent: 2}}
{% endfor %}