{%- assign tabs = 'navtabs-' | append: navtabs_id -%}
{%- for tab in environment[tabs] -%}
### {{tab[0] | liquify}}

{{tab[1].content }}
{%- endfor -%}