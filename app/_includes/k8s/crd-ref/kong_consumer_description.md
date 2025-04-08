When this resource is created, a corresponding Consumer entity will be created in {{site.base_gateway}}.
While KongConsumer exists in a specific Kubernetes namespace, KongConsumers from all namespaces
are combined into a single {{site.base_gateway}} configuration, and no KongConsumers with the same
`kubernetes.io/ingress.class` may share the same Username or CustomID value.
