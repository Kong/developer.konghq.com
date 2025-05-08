{% if include.config.header.text %}
<h2 class="flex items-center" id="{{ include.config.header.text | slugify }}">
{%- if include.config.header.icon %}
<img class="mr-1.5 w-5 h-5" src="{{ include.config.header.icon }}" />
{% endif -%}
{{ include.config.header.text | liquify | markdown }}
</h2>
{% endif %}

{% for item in include.config.blocks %}
{% if item.type == "text" %}

<p>{{ item.text | liquify | markdown }}</p>
{% endif %}

{% if item.type == "ordered_list" %}

<ol>
{% for list_item in item.items %}
<li>{{ list_item | liquify | markdown }}</li>
{% endfor %}
</ol>
{% endif %}

{% if item.type == "unordered_list" %}

<ul>
{% for list_item in item.items %}
<li>{{ list_item | liquify | markdown }}</li>
{% endfor %}
</ul>
{% endif %}

{% endfor %}
