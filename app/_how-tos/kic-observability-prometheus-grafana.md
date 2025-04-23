---
title: Prometheus & Grafana
description: "Monitor {{ site.base_gateway }} Prometheus metrics using {{ site.kic_product_name}} and Grafana"
content_type: how_to
related_resources:
  - text: All KIC documentation
    url: /index/kubernetes-ingress-controller/

permalink: /kubernetes-ingress-controller/observability/prometheus-grafana/
breadcrumbs:
  - /kubernetes-ingress-controller/
  - index: kubernetes-ingress-controller
    section: Observability

products:
  - kic

tools:
  - kic

automated_tests: false

works_on:
  - on-prem
  - konnect

entities: []

tldr:
  q: How do I monitor {{ site.base_gateway }} Prometheus metrics using Grafana?
  a: Deploy a `servicemonitor` Kubernetes resource using the {{ site.base_gateway }} Helm chart, then use a `KongClusterPlugin` to configure the `prometheus` plugin for all services in the cluster.

prereqs:
  kubernetes:
    gateway_api: true
    prometheus: true

cleanup:
  inline:
    - title: Uninstall KIC from your cluster
      include_content: cleanup/products/kic
      icon_url: /assets/icons/kubernetes.svg
---

## How it works

{{ site.base_gateway }} provides a Prometheus plugin that exports service and route metrics automatically. 

The Prometheus stack scrapes metrics from deployments that match the labels defined within a `servicemonitor` resource. The {{ site.kic_product_name }} Helm chart can automatically label your deployments and create a `servicemonitor` instance to enable Prometheus metrics scraping.

## Enable Prometheus

{{ site.base_gateway }} does not expose Prometheus metrics by default. To enable the metrics, create a `prometheus` plugin instance:

{% entity_example %}
type: plugin
data:
  name: prometheus
  config:
    status_code_metrics: true
    bandwidth_metrics: true
    upstream_health_metrics: true
    latency_metrics: true
    per_consumer: false
{% endentity_example %}

## Deploy sample services

This how-to will deploy multiple services to your Kubernetes cluster to simulate a production environment.

Deploy the services and create routing resources:

```bash
kubectl apply -f {{ site.links.web }}/manifests/kic/multiple-services.yaml -n kong
```

{% include /k8s/httproute.md release=page.release name='sample-routes' path='/billing,/comments,/invoice' service='billing,comments,invoice' port='80,80,80' skip_host=true %}

## Generate traffic

Once the service and routes are deployed, it's time to generate some fake traffic. Open a new terminal and run the following command:

```bash
while true;
do
  curl $PROXY_IP/billing/status/200
  curl $PROXY_IP/billing/status/501
  curl $PROXY_IP/invoice/status/201
  curl $PROXY_IP/invoice/status/404
  curl $PROXY_IP/comments/status/200
  curl $PROXY_IP/comments/status/200
  sleep 0.01
done
```

## Access Grafana

Grafana is an observability tool that can be used to observe Prometheus metrics over time. To access Grafana you will need to `port-forward` the services:

```bash
kubectl -n monitoring port-forward services/prometheus-operated 9090 &
kubectl -n monitoring port-forward services/promstack-grafana 3000:80 &
```

You will also need to get the password for the admin user.

Execute the following to read the password and take note of it:

```bash
kubectl get secret --namespace monitoring promstack-grafana -o jsonpath="{.data.admin-password}" | base64 --decode ; echo
```

Now, browse to [http://localhost:3000](http://localhost:3000) and use the username `admin` and the password that you made a note of.

Once logged in, you will see a `Kong (official)` dashboard in the bottom left. Click on this link.

## Metrics collected

Grafana can show the following metrics that are scraped from Prometheus.

### Request Latencies of Various Services

![Request latencies](/assets/images/kic/grafana/request-latencies.png)

Kong collects latency data of how long your services take to respond to requests. One can use this data to alert the on-call engineer if the latency goes beyond a certain threshold. For example, let’s say you have an SLA that your APIs will respond with latency of less than 20 millisecond for 95% of the requests. You could configure Prometheus to alert based on the following query:

```text
histogram_quantile(0.95, sum(rate(kong_request_latency_ms_sum{route=~"$route"}[1m])) by (le)) > 20
```

The query calculates the 95th percentile of the total request latency (or duration) for all of your services and alerts you if it is more than 20 milliseconds. The “type” label in this query is “request”, which tracks the latency added by Kong and the service. You can switch this to “upstream” to track latency added by the service only. Prometheus is highly flexible and well documented, so we won’t go into details of setting up alerts here, but you’ll be able to find them in the Prometheus documentation.

### Kong Proxy Latency

![Proxy latencies](/assets/images/kic/grafana/proxy-latencies.png)

Kong also collects metrics about its performance. The following query is similar to the previous one but gives us insight into latency added by Kong:

```text
histogram_quantile(0.90, sum(rate(kong_kong_latency_ms_bucket[1m])) by (le,service)) > 2
```

### Error Rates

![Error rates](/assets/images/kic/grafana/error-rates.png)

Another important metric to track is the rate of errors and requests your services are serving. The time series `kong_http_status` collects HTTP status code metrics for each service.

This metric can help you track the rate of errors for each of your service:

```text
sum(rate(kong_http_requests_total{code=~"5[0-9]{2}"}[1m])) by (service)
```

You can also calculate the percentage of requests in any duration that are errors. Try to come up with a query to derive that result.

Please note that all HTTP status codes are indexed, meaning you could use the data to learn about your typical traffic pattern and identify problems. For example, a sudden rise in 404 response codes could be indicative of client codes requesting an endpoint that was removed in a recent deploy.

### Request Rate and Bandwidth

![Request rates](/assets/images/kic/grafana/request-rate.png)

One can derive the total request rate for each of your services or across your Kubernetes cluster using the `kong_http_status` time series.

![Bandwidth](/assets/images/kic/grafana/bandwidth.png)

Another metric that Kong keeps track of is the amount of network bandwidth (`kong_bandwidth`) being consumed. This gives you an estimate of how request/response sizes correlate with other behaviors in your infrastructure.

You now have metrics for the services running inside your Kubernetes cluster and have much more visibility into your applications, without making any modifications in your services. You can use Alertmanager or Grafana to now configure alerts based on
the metrics observed and your SLOs.
