Check that `{{ include.config.type }}` is `{{ include.config.status }}` on the resource:

```bash
kubectl get {% if include.config.namespace %}-n {{ include.config.namespace }} {% endif %}{{ include.config.kind }} {{ include.config.name }} -o=jsonpath='{.status.conditions[?(@.type=="{{ include.config.type }}")]}'
```