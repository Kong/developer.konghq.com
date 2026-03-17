<!--vale off-->
{% table %}
columns:
  - title: Code
    key: error_code
  - title: Description
    key: description
  - title: Resolution
    key: resolution
rows:
{% for error in page.errors %}
  - error_code: {{error.key}}
    id: {{error.key}}
    description: {{error.description}}
    resolution: {{error.resolution}}
{% endfor %}
{% endtable %}
<!--vale on-->