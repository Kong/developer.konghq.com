1. Delete the zone egress `MeshMetric`, if you applied it:

   ```sh
   kubectl delete meshmetric zone-egress-metrics -n {{site.mesh_namespace}} --ignore-not-found
   ```

   This guide updated the `all-metrics`, `all-traces`, and `all-access-logs` policies from [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/) instead of creating new ones.
   To remove them, along with the `otel-collector` backend, follow that guide's cleanup steps.
   Without the `MeshMetric` policies, the sidecars stop exposing their Prometheus endpoints, and the dashboards go empty.

1. If you provisioned the Grafana dashboards as ConfigMaps, delete them:

   ```sh
   kubectl delete configmap -n mesh-observability -l grafana_dashboard=1
   ```

1. To remove the observability stack, follow the teardown steps in [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/). That guide installed the stack, and other workloads can report into it.
