```bash
curl -X POST {{ include.presenter.url }} \
    --header "accept: application/json" \
    --header "Content-Type: application/json" \
    --data '
{{ include.presenter.data | json_prettify | indent: 4 }}
    '
```
