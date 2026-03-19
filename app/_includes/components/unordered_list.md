{% for list_item in include.config.items %}
* {{ list_item.text | liquify }}
{% endfor %}