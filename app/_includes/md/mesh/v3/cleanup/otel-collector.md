1. Delete the telemetry policies and the backend they reference:

   ```sh
   kubectl delete meshaccesslog all-access-logs -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshtrace all-traces -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshmetric all-metrics -n {{site.mesh_namespace}} --ignore-not-found
   kubectl delete meshopentelemetrybackend otel-collector -n {{site.mesh_namespace}} --ignore-not-found
   ```

   Delete the policies before the collector. A policy left pointing at a backend that no longer exists keeps its `backendRef` unresolved and exports nothing, which looks like a broken collector rather than a removed one.

1. Delete the collector and its configuration:

   ```sh
   kubectl delete daemonset otel-collector -n mesh-observability --ignore-not-found
   kubectl delete service otel-collector -n mesh-observability --ignore-not-found
   kubectl delete configmap otel-collector-config -n mesh-observability --ignore-not-found
   ```

1. If you installed Tempo, Loki, and Prometheus for this guide and nothing else reports into them, remove them and the namespace:

   ```sh
   helm uninstall tempo loki prometheus -n mesh-observability
   kubectl delete namespace mesh-observability
   ```

   Leave them in place if other workloads send telemetry to them.
