<h3>{{ include.config.header.text }}</h3>

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
