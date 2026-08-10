When using a global Control Plane managed by {{site.konnect_short_name}}, use `kumactl` to manage Mesh resources there.<br>
Use `kubectl` to manage Kubernetes resources in the zone cluster. <br>`kumactl` is read-only when connected to a Control Plane running on Kubernetes.

1. In the {{site.konnect_short_name}} sidebar, click [**Service Mesh**](https://cloud.konghq.com/mesh-manager).
1. Click **example-cp**.
1. Click **Connect**.
1. Follow the steps shown in the UI to configure `kumactl`.

See the [`kumactl` command reference](/mesh/cli/#kumactl) for more information.
