{% capture block %}
```bash
{{ include.config.cmd }} {{ include.config.args | join: " " }}
```
{% endcapture %}
{% if page.output_format == 'markdown' -%}
{{block}}
{%- else -%}
{{block | markdownify}}
{%- endif -%}