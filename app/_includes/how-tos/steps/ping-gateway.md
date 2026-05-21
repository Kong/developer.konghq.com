{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

We'll be using decK for this tutorial, so let's check that {{site.base_gateway}} is running and that decK can access it:

```sh
deck gateway ping
```

If everything is running, then you should get the following response:

{% on_prem %}
content: |
  ```sh
  Successfully connected to Kong!
  Kong version: {{site.data.gateway_latest.ee-version}}
  ```
  {: .no-copy-code}
{% endon_prem %}

{% konnect %}
content: |
  ```
  Successfully Konnected to the Kong organization!
  ```
  {: .no-copy-code}
{% endkonnect %}