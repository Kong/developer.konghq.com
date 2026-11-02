{% konnect %}
content: |
  Create a `KonnectAPIAuthConfiguration` resource that stores your {{site.konnect_short_name}} personal access token:

  ```bash
  echo "
  kind: KonnectAPIAuthConfiguration
  apiVersion: konnect.konghq.com/v1alpha1
  metadata:
    name: konnect-api-auth
    namespace: kong
  spec:
    type: token
    token: '$KONNECT_TOKEN'
    serverURL: us.api.konghq.com
  " | kubectl apply -f -
  ```
{% endkonnect %}
