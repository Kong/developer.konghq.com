```bash
curl -i -X POST {{ include.presenter.url }} \
    --header "Accept: application/json" \
    --header "Content-Type: application/json" \{% if include.presenter.headers %}{%- for header in include.presenter.headers %}
    --header "{{header}}" \{% endfor %}{% endif %}
    --data '
{{ include.presenter.data | json_prettify | indent: 4 }}
    '
```