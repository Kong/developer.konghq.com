{% include operator/event-gateway-on-prem-tech-preview.md %}

To run {{ site.event_gateway }} with an on-prem control plane, you need:

* A Kubernetes cluster, with `kubectl` configured to use it.
* [Helm](https://helm.sh/docs/intro/install/), to install {{site.operator_product_name}} and Kafka.
* An {{ site.event_gateway_short }} license with the `event_gateway` entitlement, saved as `event-gateway-license.jws` in your working directory. This is a signed license token, not the JSON license file used by {{ site.ee_product_name }}. The install step stores it in a Kubernetes Secret.

You don't need a {{site.konnect_short_name}} account.
