{% navtabs include.tab_group %}
{% for item in include.config %}
{% navtab "{{ item.title }}" %}
{%- if item.content -%}
{{ item.content }}
{%- elsif item.include_content -%}
{%- assign include_path = item.include_content | append: ".md" -%}
{% include {{ include_path }} %}
{%- else -%}
{%- raise "content or include_content must be set when using the `tabs` block" -%}
{%- endif -%}
{%- endnavtab -%}
{%- endfor -%}
{%- endnavtabs -%}