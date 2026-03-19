```bash{% if should_create_namespace %}
kubectl create namespace kong --dry-run=client -o yaml | kubectl apply -f -{% endif %}
echo '
{{ config | escape_env_variables }}
' | kubectl apply -f -
```