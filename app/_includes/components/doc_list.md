{% if include.docs.size > 0 -%}
{% for doc in include.docs %}
* [{{ doc.title | liquify }}]({{doc.url }})
{% endfor -%}
{% endif %}