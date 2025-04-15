{% capture header %}
<{{ include.config.type }} id="{{ include.config.text | slugify }}" class="{% if include.config.align %}self-{{ include.config.align }}{% endif %}">{{ include.config.text | liquify }}</{{ include.config.type }}>

    {% if include.config.type == 'h1' and page.tier %}
        <div class="flex gap-2 items-center">
            {% include tier.html products=page.products tier=page.tier %}
        </div>
    {% endif %}
{% endcapture %}

{% if include.config.sub_text %}
{% if include.config.type != 'h1' %}{% raise "`sub_text` is only supported if `header.type` is `h1` in the `header` block" %}{% endif %}
<div class="flex flex-col gap-2">
{{header}}
<span class="text-xl font-light">{{include.config.sub_text | liquify }}</span>

{% if page.all_docs_indices and page.all_docs_indices != empty  %}
<div class="flex gap-2 items-center pt-2">
    {% for index in page.all_docs_indices %}
        <div class="flex gap-2 items-center w-fit badge bg-brand-saturated/40">
            <div class="flex w-3 h-3 text-brand shrink-0">{% include_svg 'assets/icons/list-ordered.svg' %}</div>
            <a class="text-primary text-xs" href="{{ index.url | liquify }}">{{ index.text | liquify }}</a>
        </div>
    {% endfor %}
</div>
{% endif %}
</div>
{% else %}
{{header}}
{% endif %}