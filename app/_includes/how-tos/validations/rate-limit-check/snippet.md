```bash
for _ in {1..{{include.iterations}}}; do
  curl -i {{include.url}} {% if include.headers %}\{%- endif -%}
     {%- for header in include.headers %}
       -H '{{header}}' {%- unless forloop.last -%}\{% endunless %}{%- endfor %}
  echo
  {%- if include.sleep %}
  sleep {{include.sleep}}{%- endif %}
done
```