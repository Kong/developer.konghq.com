If you want cert-manager to issue and rotate the admission and conversion webhook certificates, [install cert-manager](/mesh/cert-manager/) in your cluster and enable cert-manager integration by passing the following argument while installing: 

```bash
--set global.webhooks.options.certManager.enabled=true
```

If you do not enable this, the chart will generate and inject self-signed certificates automatically. This is fine for development, but for production we recommend enabling cert-manager.