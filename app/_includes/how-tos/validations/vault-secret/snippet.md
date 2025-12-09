{% assign command=include.command %}
{% if include.command == nil %}
{% assign command="docker exec " | append: include.container %}
{% endif %}

```bash
{{ command }} kong vault get {{include.secret}}
```