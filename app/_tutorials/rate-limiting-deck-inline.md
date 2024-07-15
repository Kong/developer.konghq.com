---
title: Add Rate Limiting per Service with Kong Gateway
---


Prerequisites:
* Docker: is used to run a temporary Kong Gateway and supporting databased locally for the purposes of the tutorial.
* Curl: is used to send requests to Kong Gateway. Curl is pre-installed on most Systems
* decK: is a command line tool that facilitates API Lifecycle Automation (APIOps) by offering a comprehensive toolkit of commands designed to orchestrate and automate the entire process of API delivery.


1. Get Kong

    Run Kong Gateway with the quickstart script:
    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s
    ```

    Once the Kong Gateway is ready, you will see the following message:

    ```bash
    Kong Gateway Ready 
    ```

2. Create a Service

    Add this section to your declarative configuration file `kong.yaml`:

    <button class="p-2 border bg-gray-300 float-right">Copy as curl</button><button class="p-2 border bg-gray-300 float-right">Copy as terraform</button>
    ```bash
    echo "
    _format_version: '3.0'
    services:
      - name: example_service
        url: 'http://httpbin.org'
    " >> kong.yaml
    ```

    Apply the changes:

    ```bash
    deck gateway sync kong.yaml
    ```

3. Create a Route

    Add this section to your declarative configuration file `kong.yaml`:

    <button class="p-2 border bg-gray-300 float-right">Copy as curl</button><button class="p-2 border bg-gray-300 float-right">Copy as terraform</button>
    ```bash
    echo "
    routes:
      - name: example_route
        paths:
          - /example-route
        service:
            name: example_service
    " >> kong.yaml
    ```

    Apply the changes:

    ```bash
    deck gateway sync kong.yaml
    ```

4. Enable the Rate Limiting Plugin on the Service

    Add this section to your declarative configuration file `kong.yaml`

    <button class="p-2 border bg-gray-300 float-right">Copy as curl</button><button class="p-2 border bg-gray-300 float-right">Copy as terraform</button>
    ```bash
    echo "
    plugins:
    - name: rate-limiting
      service: example_service
      config:
        hour: 5
        policy: local
    " >> kong.yaml
    ```

    Apply the changes:

    ```bash
    deck gateway sync kong.yaml
    ```

5. Validate

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
    ```

6. Cleanup
    Destroy the Kong Gateway container.

    ```bash
    curl -Ls https://get.konghq.com/quickstart | bash -s -- -d
    ```
