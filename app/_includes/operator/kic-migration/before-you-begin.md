This guide assumes a DB-less installation deployed with the `kong/kong` or `kong/ingress` Helm chart, and uses an HTTP listener on port 80.
The replacement gateway must be in the same namespace as the existing proxy Service.
If you use HTTPS or other protocols, adapt the listeners and validation requests.

You need the following tools and access:

* Administrative access to the cluster
* Bash
* Helm
* `kubectl`
* `jq`
* cert-manager

Before you start, back up your Kubernetes configuration and Helm values, and upgrade to {{ site.kic_product_name }} {{ site.data.kic_latest.release }}.
Make sure the cluster has enough capacity to run both installations at the same time.

Set the following values for your installation.
To find the existing release name and chart version, run `helm list`.
Keep the current gateway image, and choose a replica count that can serve your traffic.
{{ site.operator_product_name_short }} only deploys {{ site.base_gateway }} 3.4.1 or later.
If your current image is older, upgrade it before you start.
