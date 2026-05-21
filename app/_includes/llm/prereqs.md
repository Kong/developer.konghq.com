{%- if page.content_type == 'how_to' or page.content_type == 'cookbook' -%}{%- if page.prerequisites.any? -%}
## Prerequisites
{% prereqs %}
{%- endif -%}{%- endif -%}