If you need to use cert-manager to issue and rotate the admission and conversion webhook certificates, [install cert-manager](https://cert-manager.io/docs/installation/) to your cluster and enable cert-manager integration by passing the following arguments while installing: 

```bash
--set global.webhooks.options.certManager.enabled=true
```

If you do not enable this, the chart will generate and inject self-signed certificates automatically. We recommend enabling cert-manager to manage the lifecycle of these certificates.