1. Delete the telemetry policies and the backend they reference:

   ```sh
   kubectl delete -n {{site.mesh_namespace}} --ignore-not-found \
     meshaccesslog/all-access-logs \
     meshtrace/all-traces \
     meshmetric/all-metrics \
     meshopentelemetrybackend/otel-collector
   ```

   Delete the policies before the collector. A policy left pointing at a backend that no longer exists keeps its `backendRef` unresolved and exports nothing, which looks like a broken collector rather than a removed one.

1. Delete the collector and its configuration:

   ```sh
   kubectl delete -n mesh-observability --ignore-not-found \
     daemonset/otel-collector \
     service/otel-collector \
     configmap/otel-collector-config
   ```

1. If you installed Tempo, Loki, and Prometheus for this guide and nothing else reports into them, remove them. Leave them in place if other workloads send telemetry to them:

   ```sh
   helm uninstall tempo loki prometheus -n mesh-observability
   ```

1. Delete the namespace:

   ```sh
   kubectl delete namespace mesh-observability
   ```
