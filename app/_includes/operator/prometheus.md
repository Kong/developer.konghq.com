Monitoring your gateway is critical for understanding traffic patterns, latency, and system health. {{ site.operator_product_name }} provides two ways to collect metrics with Prometheus:

* Direct scraping: Directly scrapes standard Prometheus plugin metrics from the data plane Pods.
* Enriched metrics: Uses the `DataPlaneMetricsExtension` resource to enrich metrics with Kubernetes metadata and re-expose them via {{site.operator_product_name}}'s metrics endpoint.