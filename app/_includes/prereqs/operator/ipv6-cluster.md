This guide requires a Kubernetes cluster with IPv6 networking configured, and `kubectl` configured to point at it.
On AWS EKS, the VPC and subnets must have an IPv6 CIDR block.

{% konnect %}
content: |
  The cluster's Pods must also be able to reach IPv4 addresses.
  The {{site.konnect_short_name}} API and control plane endpoints only have IPv4 addresses, so {{ site.operator_product_name }} and the data plane can't connect to {{site.konnect_short_name}} from a cluster without IPv4 egress.
  For example, an Amazon EKS cluster with the IPv6 IP family provides IPv4 egress, but a local IPv6-only kind cluster doesn't.
{% endkonnect %}

{% on_prem %}
content: |
  If you don't have one, create a local IPv6-only cluster with [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation):

  1. Create a kind configuration file that sets the cluster's IP family to `ipv6`:

     ```bash
     cat <<EOF > kind-ipv6.yaml
     kind: Cluster
     apiVersion: kind.x-k8s.io/v1alpha4
     networking:
       ipFamily: ipv6
     EOF
     ```

  1. Create the cluster from the configuration file:

     ```bash
     kind create cluster --name kong-ipv6 --config kind-ipv6.yaml
     ```

     kind sets the current `kubectl` context to the new cluster.
{% endon_prem %}
