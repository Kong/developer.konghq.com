<!--vale off-->
{% validation custom-command %}
command: |
  kafkactl -C kafkactl.yaml --context direct create topic \
  analytics_pageviews analytics_clicks analytics_orders \
  payments_transactions payments_refunds payments_orders \
  user_actions
expected:
  return_code: 0
render_output: false
{% endvalidation %}
<!--vale on-->