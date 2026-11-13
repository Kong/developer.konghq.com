If you're in a new terminal, export the data plane address again:

```bash
export AIGW_HOST=$(kubectl get service my-ai-gateway-dp-ingress -n kong \
  -o jsonpath='{.status.loadBalancer.ingress[0].ip}')
echo $AIGW_HOST
```
