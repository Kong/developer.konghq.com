{% if include.config.header.text %}
<h3 class="flex items-center">
{%- if include.config.header.icon %}
<img class="mr-1.5 w-5 h-5" src="https://docs.konghq.com/assets/images/icons/documentation/icn-{{ include.config.header.icon }}.svg" />
{% endif -%}
{{ include.config.header.text }}
</h3>
{% endif %}

{% for item in include.config.blocks %}
{% if item.type == "text" %}

<p>{{ item.text | markdown }}</p>
{% endif %}

{% if item.type == "ordered_list" %}

<ol>
{% for list_item in item.items %}
<li>{{ list_item | markdown }}</li>
{% endfor %}
</ol>
{% endif %}

{% if item.type == "unordered_list" %}

<ul>
{% for list_item in item.items %}
<li>{{ list_item | markdown }}</li>
{% endfor %}
</ul>
{% endif %}

{% endfor %}
