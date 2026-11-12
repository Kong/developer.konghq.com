{% include operator/ai-gateway-on-prem-tech-preview.md %}

To run {{ site.ai_gateway_name }} with an on-prem control plane, you need:

* A Kubernetes cluster, with `kubectl` configured to use it.
* [Helm](https://helm.sh/docs/intro/install/), to install {{site.operator_product_name}}.
* A {{ site.ee_product_name }} license, saved as `license.json` in your working directory. The install step applies it to the cluster as a `KongLicense`.

You don't need a {{site.konnect_short_name}} account.
