{% assign konnect_token = site.data.entity_examples.config.konnect_variables.pat.placeholder %}

We'll be using decK for this tutorial, so let's check that {{site.base_gateway}} is running and that decK can access it:

```sh
deck gateway ping
```

If everything is running, then you should get the following response:

```sh
Successfully connected to Kong!
Kong version: {{site.data.gateway_latest.ee-version}}
```
{: data-deployment-topology="on-prem" .no-copy-code}

```
Successfully Konnected to the Kong organization!
```
{: data-deployment-topology="konnect" .no-copy-code}