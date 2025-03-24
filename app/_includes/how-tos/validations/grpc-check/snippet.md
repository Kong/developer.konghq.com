Use `grpcurl` to send a gRPC request through the proxy:

```bash
grpcurl -d '{{ include.payload }}' {% if include.plaintext %}-plaintext {% endif %}{% if include.authority %}-authority {{ include.authority }} {% endif %}{% unless include.plaintext %}-insecure {% endunless %}{{ include.url }}:{{ include.port }} {{ include.method }}
```

You should see the following response:

```json
{{ include.response }}
```