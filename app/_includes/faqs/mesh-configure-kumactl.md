When using a global control plane managed by {{site.konnect_short_name}}, use `kumactl` to manage {{site.mesh_product_name}} resources there, and `kubectl` to manage Kubernetes resources in the zone cluster. 

{:.info}
> `kumactl` is read-only when connected to a control plane running on Kubernetes.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Connect**.
1. Follow the steps shown in the UI to configure `kumactl`.

See the [`kumactl` command reference](/mesh/cli/#kumactl) for more information.
