{% capture header %}
<{{ include.config.type }} id="{{ include.config.text | slugify }}" class="{% if include.config.align %}self-{{ include.config.align }}{% endif %}">{{ include.config.text }}</{{ include.config.type }}>
{% endcapture %}

{% if include.config.sub_text %}
{% if include.config.type != 'h1' %}{% raise "`sub_text` is only supported if `header.type` is `h1` in the `header` block" %}{% endif %}
<div class="flex flex-col gap-2">
{{header}}
<span class="text-xl font-light">{{include.config.sub_text}}</span>
</div>
{% else %}
{{header}}
{% endif %}