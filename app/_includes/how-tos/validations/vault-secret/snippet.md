{% assign command=include.command %}
{% if include.command == "" %}
{% assign command="docker exec {{include.container}}" %}
{% endif %}

```bash
{{ command }} kong vault get {{include.secret}}
```