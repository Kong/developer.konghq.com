{% assign missing_variables = include.missing_variables %}
{% if missing_variables.size > 0 %}
  Make sure to replace the following placeholders with your own values:
  {% for variable in missing_variables %}
  * `{{ variable.placeholder }}`: {{ variable.description }}
  {% endfor %}
{% endif %}
