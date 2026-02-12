{% validation custom-command %}
command: |
  kubectl -n kong-system wait --for=condition=Available=true --timeout=120s deployment/kong-operator-kong-operator-controller-manager
expected:
  stdout: "deployment.apps/kong-operator-kong-operator-controller-manager condition met"
  return_code: 0
render_output: false
{% endvalidation %}
