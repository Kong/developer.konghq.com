{%- assign render_format_version = true %}
{%- if include.content_type == 'tutorial' and include.example_index != 1 %}
{% assign render_format_version = false %}
{%- endif %}
{: data-file="kong.yaml" }
```yaml
{%- if render_format_version %}
_format_version: '3.0'
{%- endif %}
{{ include.presenter.data }}
```
