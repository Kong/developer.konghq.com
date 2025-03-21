Use `grpcurl` to send a gRPC request through the proxy:

```bash
grpcurl -d '{{ include.payload }}'{% if include.authority %} -authority {{ include.authority }} -insecure {% endif %}{{ include.url }}:{{ include.port }} {{ include.method }}
```

The results should look like this:

```text
{{ include.response }}
```