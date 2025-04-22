```bash
curl -X POST {{ include.presenter.url }} \
    --header "accept: application/json" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer ${{ include.presenter.pat }}" \
    --data '
{{ include.presenter.data | json_prettify | escape_env_variables | indent: 4 }}
    '
```
