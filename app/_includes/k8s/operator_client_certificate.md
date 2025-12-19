{%- assign nsOpt = "" %}
{%- if include.namespace and include.namespace != "" -%}
{%- assign nsOpt = "-n " | append: include.namespace | append: " " %}
{%- endif -%}

1. Generate a new certificate and key:

   ```bash
   openssl req -new -x509 -nodes -newkey rsa:2048 -subj "/CN=kongdp/C=US" -keyout ./tls.key -out ./tls.crt
   ```

1. Create a Kubernetes secret that contains the previously created certificate:

   ```bash
   kubectl create {{ nsOpt }}secret tls konnect-client-tls --cert=./tls.crt --key=./tls.key
   ```

1. Label the `Secret` with {{ site.operator_product_name_short }}'s `Secret` label selector (default: `konghq.com/secret`):

   ```bash
   kubectl label {{ nsOpt }}secret konnect-client-tls konghq.com/secret=true
   ```

1. Label the `Secret` to tell {{ site.operator_product_name }}'s `KonnectExtension` controller to reconcile it:

   ```bash
   kubectl label {{ nsOpt }}secret konnect-client-tls konghq.com/konnect-dp-cert=true
   ```
