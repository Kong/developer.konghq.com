{% if include.method %}
```bash
{% if include.sleep %}sleep {{include.sleep}} && {% endif %}curl {% if include.display_headers %}-i {% endif %}-X {{include.method}} "{{ include.url }}" {% if include.headers %}\{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last %} \{% endunless %}{%- endfor %}{% if include.user %} \
     -u {{include.user}}{%- endif %}{% if include.body %} \
     --json '{{ include.body | json_prettify: 1 | escape_env_variables | indent: 4 | strip }}'{% endif %}
```
{% else %}
```bash
{% if include.sleep %}sleep {{include.sleep}} && {% endif %}curl {% if include.display_headers %}-i {% endif %}{{include.url }} {% if include.headers %} \{%- endif -%}{% for header in include.headers %}
     -H "{{header}}" {%- unless forloop.last -%} \{% endunless %}{%- endfor %}{% if include.user %} \
     -u {{include.user}}{%- endif %}
```
{% endif %}