
{% navtabs "gateway-version" {{heading_level}} %}
{% assign heading = heading_level | plus: 1 %}

{% for table in tables %}
{% assign tab = table[0] %}{% if page.output_format == 'markdown' %}{% assign tab = 'Gateway ' | append: table[0] %}{% endif %}
{% navtab {{tab}} %}
{%- assign columns = table[1].columns %}{% assign rows = table[1].rows -%}
{% if type == 'referenceable_fields' or type == 'priorities' or type == 'deployment_topologies' -%}
{% if page.output_format == 'markdown' -%}
{% include plugins/table.md columns=columns rows=rows type=type heading_level=heading %}
{% else -%}
{% include plugins/table.html columns=columns rows=rows type=type %}
{% endif -%}
{% else -%}
{% if page.output_format == 'markdown' -%}
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