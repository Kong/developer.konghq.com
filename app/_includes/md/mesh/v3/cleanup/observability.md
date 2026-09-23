1. Delete the telemetry policies and the backend they reference:

   ```sh
   kubectl delete meshaccesslog flight-audit-logs -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtrace flight-tracking -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshmetric kong-air-metrics zone-egress-metrics -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshopentelemetrybackend otel-collector -n {{site.mesh_namespace}} --ignore-not-found
   ```

   With the `MeshMetric` policies gone, the sidecars stop exposing their Prometheus endpoints, so the dashboards go empty.

1. If you provisioned the Grafana dashboards as ConfigMaps, delete them:

   ```sh
   kubectl delete configmap -n mesh-observability -l grafana_dashboard=1
   ```

1. To remove the observability stack itself, follow the teardown steps in [mesh observability](/mesh/observability/) and [Deploy an OpenTelemetry collector](/mesh/deploy-an-opentelemetry-collector/). Both were installed outside this guide, and other workloads may be reporting into them.
