```bash
{%- for variable in include.variables %}
export {{variable[0]}}="{{variable[1]}}"
{% endfor -%}
```