```bash
for _ in {1..{{include.iterations}}}; do
  curl  {% if include.grep %}-sv{% else %}-i{% endif %} {{include.url}} {% if include.headers %}\{%- endif -%}
     {%- for header in include.headers %}
       -H "{{header}}" {%- unless forloop.last -%}\{% endunless %}{%- endfor %} {% if include.grep -%}
       2>&1 | grep -E "{{ include.grep }}"{% endif %}
  echo
  {%- if include.sleep %}
  sleep {{include.sleep}}{%- endif %}
done
```