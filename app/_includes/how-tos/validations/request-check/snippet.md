{% if include.method %}
```bash
curl -i -X {{include.method}} {{include.url}} {% if include.headers %}\{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%}\{% endunless %}{%- endfor %}{% if include.body %}\
     --data-raw '
{{ include.body | json_prettify | indent: 4 }}
    '{% endif %}
```
{% else %}
```bash
curl -i {{include.url}} {% if include.headers %}\{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%}\{% endunless %}{%- endfor %}
```
{% endif %}