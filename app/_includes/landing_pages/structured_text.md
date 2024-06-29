<h3 class="text-xl mb-2">{{ include.config.header.text }}</h3>

{% for item in include.config.blocks %}
{% if item.type == "text" %}

<p class="mb-2">{{ item.text | markdown }}</p>
{% endif %}

{% if item.type == "ordered_list" %}

<ol class="list-decimal mb-2 ml-4">
{% for list_item in item.items %}
<li>{{ list_item | markdown }}</li>
{% endfor %}
</ol>
{% endif %}

{% if item.type == "unordered_list" %}

<ul class="list-disc mb-2 ml-4">
{% for list_item in item.items %}
<li>{{ list_item | markdown }}</li>
{% endfor %}
</ul>
{% endif %}

{% endfor %}
