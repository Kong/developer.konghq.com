---
title: Configure data streaming with the Confluent plugin
content_type: how_to
related_resources:
  - text: Rotate secrets in Google Cloud Secret with {{site.base_gateway}}
    url: /how-to/rotate-secrets-in-google-cloud-secret/
  - text: Secrets management
    url: /secrets-management/
  - text: Configure Google Cloud Secret Manager as a Vault entity in {{site.base_gateway}}
    url: /how-to/configure-google-cloud-secret-as-a-vault-backend/
description: placeholder
products:
    - gateway


works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.8'

entities: 
  - plugin

tags:
    - security

tldr:
    q: Placeholder
    a: Placeholder

tools:
    - deck

prereqs:
  entities:
    services:
        - example-service
    routes:
        - example-route
  inline:
    - title: Confluent set up
      position: before
      content: |
        Follow the links to Confluent's documentation site to:
        1. [Create a Kafka cluster in Confluent Cloud](https://docs.confluent.io/cloud/current/get-started/index.html#step-1-create-a-ak-cluster-in-ccloud)
        2. [Create a Kafka topic in the cluster](https://docs.confluent.io/cloud/current/get-started/index.html#step-2-create-a-ak-topic) called `kong-test`.


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---

@TODO - Validation step isn't working

## Generate a API key in Confluent Cloud

To authorize access from the plugin to your cluster, you need to generate an API Key and secret.
From your cluster in Confluent Cloud, click API keys in the sidebar and create a new key. Copy the API key and secret values.

## Create decK environment variables 

We'll use decK environment variables for several of the Confluent Cloud values in the {{site.base_gateway}} plugin configuration. This is because these values typically can vary between environments. 

You can find your cluster bootstrap server in your Cluster settings in Confluent Cloud. 

```
export DECK_CONFLUENT_HOST='<cluster-bootstrap-server>'
export DECK_CONFLUENT_TOPIC='kong-test'
export DECK_CONFLUENT_API_KEY='<cluster-api-key>'
export DECK_CONFLUENT_API_SECRET='<cluster-api-secret>'
```


## Enable the Confluent plugin

Enable the Confluent plugin on the Route:

{% entity_examples %}
entities:
  plugins:
    - name: confluent
      route: example-route
      config:
        bootstrap_servers:
        - host: ${confluent_host}
          port: 9092
        topic: ${confluent_topic}
        cluster_api_key: ${confluent_api_key}
        cluster_api_secret: ${confluent_api_secret}

variables:
  confluent_host:
    value: $CONFLUENT_HOST
  confluent_port:
    value: $CONFLUENT_PORT
  confluent_topic:
    value: $CONFLUENT_TOPIC
  confluent_api_key:
    value: $CONFLUENT_API_KEY
  confluent_api_secret:
    value: $CONFLUENT_API_SECRET
{% endentity_examples %}

Clusters use port `9092` by default.

## Validate

<!--fix!-->

Send a request to the Route to validate.

{% validation request-check %}
url: /anything
status_code: 201
method: POST
headers:
    - 'Host: example-route'
    - 'Content-Type: application/json'
body:
    foo: bar
{% endvalidation %}

You should receive a `200 { message: "message sent" }` response.

To validate that the message was added to the topic in the Confluent Cloud console, do the following:
1. From the navigation menu, select **Topics** to show the list of topics in your cluster.
2. Select the topic you sent messages to.
3. In the topic detail page, select the **Messages** tab to view the messages being produced to the topic.