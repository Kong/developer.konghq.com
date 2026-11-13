{% on_prem %}
content: |
  Apply your {{site.ee_product_name}} license as a `KongLicense` resource:

  ```bash
  echo "
  apiVersion: configuration.konghq.com/v1alpha1
  kind: KongLicense
  metadata:
    name: kong-license
  rawLicenseString: '$(cat ./license.json)'
  " | kubectl apply -f -
  ```

  This assumes that your license is available in `./license.json`.
{% endon_prem %}
