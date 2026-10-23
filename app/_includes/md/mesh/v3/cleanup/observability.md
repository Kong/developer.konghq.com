1. Delete the telemetry policies and the backend they reference:

   ```sh
   kubectl delete meshaccesslog flight-audit-logs -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtrace flight-tracking -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshmetric kong-air-metrics zone-egress-metrics -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshopentelemetrybackend otel-collector -n {{site.mesh_namespace}} --ignore-not-found
   ```

   Without the `MeshMetric` policies, the sidecars stop exposing their Prometheus endpoints, and the dashboards go empty.

1. If you provisioned the Grafana dashboards as ConfigMaps, delete them:

   ```sh
   kubectl delete configmap -n mesh-observability -l grafana_dashboard=1
   ```

1. To remove the observability stack, follow the teardown steps in [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/). That guide installed the stack, and other workloads can report into it.
