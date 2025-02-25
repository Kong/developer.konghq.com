{% if include.method %}
```bash
{% if include.sleep %}sleep {{include.sleep}}{% endif %}curl -i -X {{include.method}} {{include.url }} {% if include.headers %}\{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%}\{% endunless %}{%- endfor %}{% if include.user %}\
     -u {{include.user}}{%- endif %}{% if include.body %}\
     --data-raw '
{{ include.body | json_prettify | escape_env_variables | indent: 4 }}
    '{% endif %}
```
{% else %}
```bash
{% if include.sleep %}sleep {{include.sleep}}{% endif %}curl -i {{include.url }} {% if include.headers %}\{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%}\{% endunless %}{%- endfor %}{% if include.user %}\
     -u {{include.user}}{%- endif %}
```
{% endif %}