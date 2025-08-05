   ```bash
   helm upgrade --install ko kong/kong-operator -n kong-system --create-namespace \
     --set kubernetes-configuration-crds.enabled=true \
     --set env.ENABLE_CONTROLLER_KONNECT=true{% if prereqs.operator.controllers %} \{% for controller in prereqs.operator.controllers %}
     --set env.ENABLE_CONTROLLER_{{ controller | upcase }}=true{% unless forloop.last %} \{% endunless %}{% endfor %}{% endif %}
   ```
