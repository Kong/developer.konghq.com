{% if page.output_format == 'markdown' %}
{{include.content | liquify}}
{%- else -%}
<div class="card flex-col gap-5 p-6 pb-4">
    <div class="flex items-center">
        <img src="/assets/icons/{{include.icon}}" class="w-10 m-3 inline-block">
        {{include.content | liquify}}
    </div>
</div>
{%- endif %}