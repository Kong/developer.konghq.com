{% assign summary = "Deploy Keycloak" %}
{% assign icon_url = "/assets/icons/keycloak.svg" %}

{% capture details_content %}
This how-to uses Keycloak as an OpenID Connect provider.

### Install Keycloak

```
kubectl apply -f https://raw.githubusercontent.com/keycloak/keycloak-quickstarts/refs/heads/main/kubernetes/keycloak.yaml -n kong
```

### Create a Route

We'll use {{ site.base_gateway }} to expose Keycloak in our cluster on a custom domain:
<!--vale off-->
{% httproute %}
name: keycloak
matches:
  - path: /
    service: keycloak
    port: 8080
hostname: 'keycloak.$PROXY_IP.nip.io' 
{% endhttproute %}
<!--vale on-->
### Register a client and user

Set two variables containing your client ID and secret:

```bash
export CLIENT_ID=kong
export CLIENT_SECRET=this_is_sup3r_secret
```

To call the Keycloak admin API, fetch an access token using the `password` grant type:

{:.warning}
> You may need to wait for Keycloak to be deployed before calling the API. Run `kubectl get pods -n kong` and wait until the Keycloak pod is ready.

```bash
ACCESS_TOKEN=$(curl -sSk -X POST "https://keycloak.$PROXY_IP.nip.io/realms/master/protocol/openid-connect/token" \
     -d client_id="admin-cli" -d username=admin -d password=admin -d grant_type=password | jq -r .access_token)
```

Next, create a new `openid-connect` client:

<!--vale off-->
{% http_request %}
url: https://keycloak.$PROXY_IP.nip.io/admin/realms/master/clients
insecure: true
method: POST
headers:
  - "Authorization: Bearer $ACCESS_TOKEN"
body:
  protocol: openid-connect
  clientId: $CLIENT_ID
  secret: $CLIENT_SECRET
  standardFlowEnabled: true
  redirectUris:
    - http://$PROXY_IP/*
{% endhttp_request %}
<!--vale on-->

Finally, register a user named `alex` with the password `password`:

<!--vale off-->
{% http_request %}
url: https://keycloak.$PROXY_IP.nip.io/admin/realms/master/users
insecure: true
method: POST
headers:
  - "Authorization: Bearer $ACCESS_TOKEN"
body:
  username: alex
  enabled: true
  credentials:
    - type: password
      value: "password"
      temporary: false
{% endhttp_request %}
<!--vale on-->

You are now ready to configure the OpenID Connect plugin

{% endcapture %}

{% unless include.render_inline %}
{% include how-tos/prereq_cleanup_item.html summary=summary details_content=details_content icon_url=icon_url %}
{% else %}
## {{ summary }}

{{ details_content }}
{% endunless %}