
{% tabs codeblock %}
{% tab kumactl %}
```shell
kumactl install control-plane \
  {{ config.helm_flags }} \
  | kubectl apply -f -
```
{:.no-line-numbers}
{% endtab %}
{% tab Helm %}
```shell
# Before installing {{ config.product_name }} with Helm, configure your local Helm repository:
# {{ config.web_url }}/{{ config.product_url_segment }}/{{ config.page_release }}/production/cp-deployment/kubernetes/#helm
helm install \
  --create-namespace \
  --namespace {{ config.namespace }} \
  {{ config.helm_flags }} \
  {{ config.helm_install_name }} {{ config.helm_repo }}
```
{:.no-line-numbers}
{% endtab %}
{% endtabs %}
