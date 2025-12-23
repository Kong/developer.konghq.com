## Configure plugins

This how-to requires three plugins to demonstrate how fallback configuration works.

1. As the example uses a [Consumer](/gateway/entities/consumer/), we need to create an authentication plugin to identify the incoming request:

{% entity_example %}
type: plugin
cluster_plugin: false
data:
  name: key-auth

  skip_annotate: true
indent: 4
{% endentity_example %}

1. Unidentified traffic has a base rate limit of one request per second:

{% entity_example %}
type: plugin
cluster_plugin: false
data:
  name: rate-limit-base
  plugin: rate-limiting
  config:
    second: 1
    policy: local
  
  skip_annotate: true
indent: 4
{% endentity_example %}

1. Identified Consumers have a rate limit of five requests per second:

{% entity_example %}
type: plugin
data:
  name: rate-limit-consumer
  plugin: rate-limiting
  config:
    second: 5
    policy: local
  
  route: route-b
  skip_annotate: true
indent: 4
{% endentity_example %}

## Create Routes

Let's create two Routes for testing purposes:

* `route-a` has no plugins attached
* `route-b` has the three plugins created above attached
<!--vale off-->
{% httproute %}
name: route-a
matches:
  - path: /route-a
    service: echo
    port: 1027
skip_host: true
{% endhttproute %}

{% httproute %}
name: route-b
matches:
  - path: /route-b
    service: echo
    port: 1027
skip_host: true
annotation_plugins:
  - key-auth
  - rate-limit-base
  - rate-limit-consumer
{% endhttproute %}
<!--vale on-->
## Create a Consumer

Finally, let's create a `KongConsumer` with credentials and associate the `rate-limit-consumer` `KongPlugin`.

Create a Secret containing the `key-auth` credential:

```bash
echo 'apiVersion: v1
kind: Secret
metadata:
  name: bob-key-auth
  namespace: kong
  labels:
    konghq.com/credential: key-auth
stringData:
  key: bob-password
' | kubectl apply -f -
```

Then create a `KongConsumer` that references this Secret:

{% entity_example %}
type: consumer
data:
  username: bob
  credentials:
  - bob-key-auth
  plugins:
  - rate-limit-consumer
{% endentity_example %}

## Validate the Routes

At this point we can validate that our Routes are working as expected.

### Route A

`route-a` is accessible without any authentication and will return an `HTTP 200`:

{% validation request-check %}
url: /route-a
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:
```text
Welcome, you are connected to node orbstack.
Running on Pod echo-74c66b778-szf8f.
In namespace default.
With IP address 192.168.194.13.
```
{:.no-copy-code}

### Route B

Authenticated requests with the valid `apikey` header on the `route-b` should be accepted:

{% validation request-check %}
url: /route-b
headers:
  - "apikey:bob-password"
status_code: 200
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:

```text
Welcome, you are connected to node orbstack.
Running on Pod echo-74c66b778-szf8f.
In namespace default.
With IP address 192.168.194.13.
```
{:.no-copy-code}

Requests without the `apikey` header should be rejected:

{% validation request-check %}
url: /route-b
status_code: 401
on_prem_url: $PROXY_IP
konnect_url: $PROXY_IP
{% endvalidation %}

The results should look like this:

```text
{
  "message":"No API key found in request",
  "request_id":"520c396c6c32b0400f7c33531b7f9b2c"
}
```
{:.no-copy-code}