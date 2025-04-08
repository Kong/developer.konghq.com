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

<br />
{{ include.output.explanation }}
<br />

{% if include.output.expected %}
```text{% for v in include.output.expected %}{% for r in v.value %}
{{ r }}{% endfor %}
{% endfor -%}
```
{% endif %}