This guide deletes and recreates a Kubernetes cluster to simulate a cluster loss.
Use a dedicated local cluster, not a cluster that runs other workloads.

1. Install [k3d](https://k3d.io/):

   ```bash
   curl -s https://raw.githubusercontent.com/k3d-io/k3d/main/install.sh | bash
   ```

1. Create a cluster named `kong-dr`:

   {% capture k3d_cluster %}{% include k8s/disaster-recovery/k3d-cluster.md %}{% endcapture %}
   {{ k3d_cluster | indent }}
