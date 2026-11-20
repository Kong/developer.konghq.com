| AI Policy | Priority |
|--------|----------|
{% for row in rows %}| [{{ row.title }}]({{ row.url }}) (`{{ row.slug }}`) | {{ row.priority }} |
{% endfor %}
