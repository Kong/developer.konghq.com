{%- assign tabs = 'navtabs-' | append: navtabs_id -%}
{%- for tab in environment[tabs] -%}
{% for i in (1..heading_level) %}#{% endfor %} {{tab[0] | liquify}}
{{tab[1].content }}
{%- endfor -%}