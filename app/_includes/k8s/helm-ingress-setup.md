{% unless include.skip_ingress_controller_install %}
## Configure your Ingress Controller

To expose the Admin API, you need an Ingress Controller running in your cluster. Choose a provider and ensure that your Ingress controller is configured correctly:

{% include k8s/cloud-ingress-controller-install-tabs.md indent=true service=include.service release=include.release %}

{% endunless %}

## Define Ingress annotations 

Configure the `{{ include.service }}` section in `values-{{ include.release }}.yaml`. Replace `example.com` with your custom domain name.

{% include k8s/cloud-ingress-controller-create-ingress.md indent=true service=include.service type=include.type %}

{% unless include.skip_release %}

## Helm upgrade

Run `helm upgrade` to update the release.

```bash
helm upgrade kong-{{ include.release }} kong/kong -n kong --values ./values-{{ include.release }}.yaml
```
{% endunless %}

{% unless include.skip_dns %}
## Update DNS

Fetch the `Ingress` IP address and update your DNS records to point at the Ingress address. You can configure DNS manually, or use a tool like [external-dns](https://github.com/kubernetes-sigs/external-dns) to automate DNS configuration.

```bash
kubectl get ingress -n kong kong-{{ include.release }}-kong-{{ include.service }} \
  -o jsonpath='{.spec.rules[0].host}{": "}{range .status.loadBalancer.ingress[0]}{@.ip}{@.hostname}{end}'
```
{% endunless %}