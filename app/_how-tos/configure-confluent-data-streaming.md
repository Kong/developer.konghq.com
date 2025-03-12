---
title: Configure Google Cloud Secret Manager with Workload Identity in {{site.base_gateway}}
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
        2. [Create a Kafka topic in the cluster](https://docs.confluent.io/cloud/current/get-started/index.html#step-2-create-a-ak-topic) `kong-test`

        Confluent env var:


cleanup:
  inline:
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
---


## Generate API Key

To authorize access from the plugin to your cluster, you need to generate an API Key and secret.
In the **Kafka credentials** pane, leave **Global access** selected, and click **Generate API key & download**. This creates an API key and secret that allows the plugin to access your cluster, and downloads the key and secret to your computer.

## Enable the Confluent plugin

Enable the Confluent plugin on the route with the following command:

{% entity_examples %}
entities:
  plugins:
    - name: confluent
    route: example-route
    config:
        bootstrap_servers:
        - host: my-bootstrap-server
          port: my-bootstrap-port
        topic: kong-test
        cluster_api_key: my-api-key
        cluster_api_secret: my-api-secret
{% endentity_examples %}

## Validate

You can make a sample request with:

``` bash
curl -X POST http://localhost:8000 --header 'Host: test-confluent' foo=bar
```

You should receive a `200 { message: "message sent" }` response.

To validate that the message was added to the topic in the Confluent Cloud console, do the following:
1. From the navigation menu, select **Topics** to show the list of topics in your cluster.
2. Select the topic you sent messages to.
3. In the topic detail page, select the **Messages** tab to view the messages being produced to the topic.