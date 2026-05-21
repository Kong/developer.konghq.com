{% if page.output_format == 'markdown' %}
* {% if cta_url %}[{{title | liquify}}]({{cta_url}}){% else %}{{title | liquify}}{% endif %}
{%- else -%}
{% capture card_content %}
<img src="/assets/icons/{{icon | liquify}}" class="w-10 m-3 inline-block">
{{title | liquify}}
{% endcapture %}
<div class="card card__bordered flex-col gap-5">
{% if cta_url %}
    <a href="{{cta_url}}" class="flex gap-5 hover:no-underline w-full items-center p-6 text-primary">
    {{card_content}}
    </a>
{% else %}
    <div class="flex items-center p-6">
{{card_content}}
    </div>
{% endif %}
</div>
{%- endif %}