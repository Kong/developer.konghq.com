{%- assign api = site.data.ssg_api_pages | where_exp: "page", "page.title == include.config.title" | first -%}
{% if page.output_format == 'markdown' -%}
{% include card.md title=api.title description=api.description cta_text='See reference' cta_url=api.url heading_level=include.heading_level%}
{%- else -%}
{% include card.html title=api.title description=api.description cta_text='See reference' cta_url=api.url %}
{% endif %}