---
title: Enable rate limiting on a service
related_resources:
  - text: How to create rate limiting tiers
    url: https://docs.konghq.com/gateway/api/admin-ee/latest/
  - text: Rate Limiting Advanced plugin
    url: https://docs.konghq.com/hub/kong-inc/rate-limiting-advanced/

entities: 
    - service
    - plugin
content_type: tutorial

test: 
    - /tests/rate-limiting-service.py
---

## Prerequisites 

place holder for prerendered prereq instructions that contains: 

* Docker: Docker is used to run a temporary Kong Gateway and database to allow you to run this tutorial
* curl: curl is used to send requests to Kong Gateway . 
* Kong Gateway: 

    curl -Ls https://get.konghq.com/quickstart | bash -s


This script will run Kong Gateway in Docker and create  the Services and Routes we will use in the tutorial.

The created entities we will use in this tutorial are:
A Gateway Service: `example-service` with the serviceid: `12312312313`


## Enable the rate limiting plugin


1. Enable the Rate Limiting Plugin on the Service
{% navtabs %}
{% navtab Admin API%}

        curl -X POST http://localhost:8001/services/{serviceName|Id}/plugins \
            --header "accept: application/json" \
            --header "Content-Type: application/json" \
            --data '{
                "name": "rate-limiting",
                "config": {
                    "second": 5,
                    "hour": 10000,
                    "policy": "local"
                    }
                }'

{% endnavtab %}
{% navtab Konnect%}
Make the following request, substituting your own access token, region, control plane ID, and service ID:

    curl -X POST \
    https://{us|eu}.api.konghq.com/v2/control-planes/{controlPlaneId}/core-entities/services/12312312313/plugins \
        --header "accept: application/json" \
        --header "Content-Type: application/json" \
        --header "Authorization: Bearer TOKEN" \
        --data '{"name":"rate-limiting","config":{"second":5,"hour":10000,"policy":"local"}}'
{% endnavtab %}
{% navtab Tab decK %}

1. Add this section to your declarative configuration file `kong.yaml`:

 ```
    echo "
    _format_version: '3.0'
    plugins:
    - name: rate-limiting
    service: example_service
    config:
        second: 5
        hour: 10000
        policy: local
        " >> kong.yaml
```

2. Apply the changes:

    ```bash
    deck gateway sync kong.yaml
    ```
{% endnavtab %}
{% navtab Tab Kubernetes %}

1. Create a KongPlugin resource:
    ```bash
    echo "
        apiVersion: configuration.konghq.com/v1
        kind: KongPlugin
        metadata:
        name: rate-limiting-example
        plugin: rate-limiting
        config:
        second: 5
        hour: 10000
        policy: local
        " | kubectl apply -f -
    ```
2. Next, apply the KongPlugin resource to an ingress by annotating the service as follows: 
    
       kubectl annotate service SERVICE_NAME konghq.com/plugins=rate-limiting-example

{% endnavtab %}
{% endnavtabs %}


## Validate

After configuring the Rate Limiting plugin, you can verify that it was configured correctly and is working, by sending more requests then allowed in the configured time limit.

    ```bash
    for _ in {1..6}
    do
      curl http://localhost:8000/example-route/anything/
    done
    ```
    After the 5th request, you should receive the following `429` error:

    ```bash
    { "message": "API rate limit exceeded" }



## Teardown

Destroy the Kong Gateway container.

    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
    ```

## Related Resources
Generated from front matter.

