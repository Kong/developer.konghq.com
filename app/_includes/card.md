{% for i in (1..include.heading_level) %}#{% endfor %} {{include.title | liquify}}

{{include.description | liquify}}

{% if include.cta_text -%}{% if include.cta_url %}[{{include.cta_text | liquify}}]({{include.cta_url}}){% else %}{{include.cta_text | liquify}}{% endif %}{% endif -%}
{% for cta in include.ctas %}
* [{{cta.text | liquify}}]({{cta.url}})
{% endfor %}