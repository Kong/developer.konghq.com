```sh
{{include.config.base_command}} \
{%- for flag in include.config.flags %}
  --config {{flag}}{%- unless forloop.last %} \{% endunless %}{%- endfor %}
```

And ask a question to confirm that requests reach {{site.ai_gateway}}.

```text
{{ include.config.prompt }}
```
