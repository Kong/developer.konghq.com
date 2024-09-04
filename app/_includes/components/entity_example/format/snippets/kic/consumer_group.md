```yaml
apiVersion: configuration.konghq.com/v1
kind: KongConsumerGroup
metadata:
  name: { { include.presenter.data.name } }
  annotations:
    kubernetes.io/ingress.class: kong
```
