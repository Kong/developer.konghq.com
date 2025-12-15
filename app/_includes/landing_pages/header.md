{% capture header %}
<{{ include.config.type }} id="{{ include.config.text | liquify | slugify }}" class="{% if include.config.align %}self-{{ include.config.align }}{% endif %}">{{ include.config.text | liquify }}</{{ include.config.type }}>

    {% if include.config.type == 'h1' %}
        <div class="flex gap-2 items-center">
        {% if page.tier %}
            {% include tier.html products=page.products tier=page.tier %}
        {% endif %}
         {%- if page.beta == true or page.tech_preview == true -%}
            {%- include_cached badges/stage.html beta=page.beta tech_preview=page.tech_preview -%}
         {% endif %}
        </div>
    {% endif %}

    {% unless include.config.sub_text %}
    {% if  include.config.type == 'h1' and page.all_docs_indices and page.all_docs_indices != empty %}
        <div class="flex gap-2 items-center">
            {% for index in page.all_docs_indices %}
                {% include_cached index_link.html index=index %}
            {% endfor %}
        </div>
    {% endif %}
    {% endunless %}
{% endcapture %}

{% if include.config.sub_text %}
{% if include.config.type != 'h1' and include.config.type != 'h2' %}{% raise "`sub_text` is only supported if `header.type` is `h1/h2` in the `header` block" %}{% endif %}
<div class="flex flex-col gap-2">
{{header}}
<span class="{% if include.config.type == 'h1'%}text-xl{% else %}text-lg{% endif %} font-light">{{include.config.sub_text | liquify }}</span>

{% if  include.config.type == 'h1' and page.all_docs_indices and page.all_docs_indices != empty  %}
<div class="flex gap-2 items-center pt-2">
    {% for index in page.all_docs_indices %}
      {% include_cached index_link.html index=index %}
    {% endfor %}
</div>
{% endif %}
</div>
{% else %}
{{header}}
{% endif %}