{% if include.config.header.text %}## {{include.config.header.text | liquify}}{% endif -%}
{% for item in include.config.blocks %}
{% if item.type == "text" %}{{ item.text | liquify}}{% endif -%}
{% if item.type == "ordered_list" %}{% for list_item in item.items %}
1. {{ list_item | liquify  }}
{% endfor %}{% endif %}
{% if item.type == "unordered_list" %}{% for list_item in item.items %}
* {{ list_item | liquify }}
{% endfor %}{% endif %}{% endfor -%}