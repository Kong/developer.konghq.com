```bash
for _ in {1..{{include.iterations}}}; do
  curl  {% if include.grep %}-sv{% else %}-i{% endif %} {{include.url}} {% if include.headers %}\{%- endif -%}
     {%- for header in include.headers %}
       -H "{{header}}" {%- unless forloop.last -%}\{% endunless %}{%- endfor %} {% if include.body %} \
       --json '{{ include.body | json_prettify: 1 | escape_env_variables | indent: 4 | strip }}'{% endif %} {% if include.grep -%}
       2>&1 | grep -E "{{ include.grep }}"{% endif %}
  echo
  {%- if include.sleep %}
  sleep {{include.sleep}}{%- endif %}
done
```
{% if include.output.explanation %}
<br />
{{ include.output.explanation }}
<br />
{% endif %}
{% if include.output.expected %}
```text{% for v in include.output.expected %}{% for r in v.value %}
{{ r }}{% endfor %}
{% endfor -%}
```
{:.no-copy-code}
{% endif %}