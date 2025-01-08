```bash
curl {{include.url}} {% if include.headers %}\{%- endif -%}
    {%- for header in include.headers %}
     -H '{{header}}' {%- unless forloop.last -%}\{% endunless %}{%- endfor %}
```
