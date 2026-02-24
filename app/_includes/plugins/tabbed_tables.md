
{% navtabs "gateway-version" %}

{% for table in tables %}
{% navtab {{table[0]}} %}
{%- assign columns = table[1].columns %}{% assign rows = table[1].rows -%}
{% if type == 'referenceable_fields' or type == 'priorities' or type == 'deployment_topologies' -%}
{% include plugins/table.html columns=columns rows=rows type=type %}
{% else -%}
{% if page.output_format == 'markdown' -%}
{% assign heading = heading_level | plus: 1 %}
{% include components/feature_table.md columns=columns rows=rows sticky=true item_title="Plugin" center_values=true heading_level=heading %}
{% else -%}
<div class="max-h-[50vh] overflow-y-auto rounded-lg">
    {% include components/feature_table.html columns=columns rows=rows sticky=true item_title="Plugin" center_values=true %}
</div>
{% endif -%}
{% endif -%}
{% endnavtab %}
{% endfor %}

{% endnavtabs %}