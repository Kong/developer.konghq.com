{%- if include.config.gateway_api != false -%}
{%- assign summary = "Install Prometheus" -%}
{%- assign icon_url = "/assets/icons/prometheus.svg" -%}
{%- capture details_content %}

Create a `values-monitoring.yaml` file to set the scrape interval, use Grafana persistence, and install {{site.base_gateway}}'s dashboard:
```yaml
prometheus:
  prometheusSpec:
    scrapeInterval: 10s
    evaluationInterval: 30s
grafana:
  persistence:
    enabled: true  # enable persistence using Persistent Volumes
  dashboardProviders:
    dashboardproviders.yaml:
      apiVersion: 1
      providers:
      - name: 'default' # Configure a dashboard provider file to
        orgId: 1        # put Kong dashboard into.
        folder: ''
        type: file
        disableDeletion: false
        editable: true
        options:
          path: /var/lib/grafana/dashboards/default
  dashboards:
    default:
      kong-dash:
        gnetId: 7424  # Install the following Grafana dashboard in the
        revision: 11  # instance: https://grafana.com/dashboards/7424
        datasource: Prometheus
      kic-dash:
        gnetId: 15662
        datasource: Prometheus
```

To install Prometheus and Grafana, execute the following, specifying the path to the `values-monitoring.yaml` file that you created:

```bash
kubectl create namespace monitoring
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm install promstack prometheus-community/kube-prometheus-stack --namespace monitoring --version 52.1.0 -f values-monitoring.yaml
```

By default, kube-prometheus-stack [selects ServiceMonitors and PodMonitors by a `release` label equal to the release name](https://github.com/prometheus-community/helm-charts/blob/kube-prometheus-stack-19.0.1/charts/kube-prometheus-stack/values.yaml#L2128-L2169). We will set the `release` label when we install {{ site.kic_product_name }}.
{%- endcapture -%}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}
{%- endif -%}