{% capture block %}
```bash
{{ include.config.cmd }} {{ include.config.args | join: " " }}
```
{% endcapture %}
{{block | markdownify}}