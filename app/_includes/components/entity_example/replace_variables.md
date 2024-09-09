{% assign missing_variables = include.missing_variables %}
{% if missing_variables.size > 0 %}
<div class="prose-ul:list-disc" markdown="1">
  Make sure to replace the following placeholders with your own values:
  {% for variable in missing_variables %}
  * `{{ variable.placeholder }}`: {{ variable.description }}
  {% endfor %}
</div>
{% endif %}
