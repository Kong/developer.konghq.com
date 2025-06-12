---
title: Configure CyberArk Conjur as a vault backend
content_type: how_to
description: "Learn how to reference CyberArk Conjur secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.11'

entities: 
  - vault

tags:
    - secrets-management
    - security
    - cyberark-conjur
search_aliases:
  - Conjur
tldr:
    q: How can I access CyberArk Conjur secrets in {{site.base_gateway}}? 
    a: |
      Configure a Vault entity with `config.auth_method: api_key`, your Conjur endpoint URL (`config.endpoint_url`), account name (`config.account`), login (`config.login`), and API key (`config.api_key`). Reference the secret like `{vault://conjur-vault/BotApp%2FsecretVar}`, assuming your Vault prefix is `conjur-vault` and your secret was stored as `BotApp/secretVar`.

tools:
    - deck

prereqs:
  inline: 
    - title: CyberArk Conjur
      content: |
        To run this tutorial, you'll need to run the CyberArk Conjur quickstart in Docker:
        1. Clone the `conjur-quickstart` GitHub repository:
           ```sh
           git clone https://github.com/cyberark/conjur-quickstart.git
           ```
        1. Navigate to the `conjur-quickstart` directory:
           ```sh
           cd conjur-quickstart
           ```
        1. Modify the `docker-compose.yml` file in this directory to change the proxy port from `8443` to `9443`:
           ```yaml
           services:
            openssl:
                image: cyberark/conjur
                container_name: openssl
                entrypoint:
                - openssl
                - req
                - -newkey
                - rsa:2048
                - -days
                - "365"
                - -nodes
                - -x509
                - -config
                - /tmp/conf/tls.conf
                - -extensions
                - v3_ca
                - -keyout
                - /tmp/conf/nginx.key
                - -out
                - /tmp/conf/nginx.crt
                volumes:
                - ./conf/tls/:/tmp/conf

            bot_app:
                image: cfmanteiga/alpine-bash-curl-jq
                privileged: true
                container_name: bot_app
                command: tail -F anything
                volumes:
                - ./program.sh:/tmp/program.sh
                restart: on-failure

            database:
                image: postgres:15
                container_name: postgres_database
                environment:
                POSTGRES_HOST_AUTH_METHOD: password
                POSTGRES_PASSWORD: SuperSecretPg
                ports:
                - "8432:5432"

            pgadmin:
            #    https://www.pgadmin.org/docs/pgadmin4/latest/container_deployment.html
                image: dpage/pgadmin4
                environment:
                PGADMIN_DEFAULT_EMAIL: user@domain.com
                PGADMIN_DEFAULT_PASSWORD: SuperSecret
                ports:
                - "8081:80"

            conjur:
                image: cyberark/conjur
                container_name: conjur_server
                command: server
                environment:
                DATABASE_URL: postgres://postgres:SuperSecretPg@database/postgres
                CONJUR_DATA_KEY:
                CONJUR_AUTHENTICATORS:
                CONJUR_TELEMETRY_ENABLED: 'false'
                depends_on:
                - database
                restart: on-failure
                ports:
                - "8080:80"

            proxy:
                image: nginx:latest
                container_name: nginx_proxy
                ports:
                - "9443:443"
                volumes:
                - ./conf/:/etc/nginx/conf.d/:ro
                - ./conf/tls/:/etc/nginx/tls/:ro
                depends_on:
                - conjur
                - openssl
                restart: on-failure

            client:
                image: cyberark/conjur-cli:8
                container_name: conjur_client
                depends_on: [ proxy ]
                entrypoint: sleep
                command: infinity
                volumes:
                - ./conf/policy:/policy
           ```
           
           {:.warning}
           > **Important:** We're using port `9443` instead of `8443` here because {{site.base_gateway}} also uses port `8443` and both will be running in Docker containers.
        1. Finish [setting up the Conjur OSS environment](https://www.conjur.org/get-started/quick-start/oss-environment/).
        1. [Define a policy](https://www.conjur.org/get-started/quick-start/define-policy/).
        1. [Store a secret](https://www.conjur.org/get-started/quick-start/store-secret/).
        1. Export the Conjur environment variables:
           ```sh
           export DECK_CONJUR_ENDPOINT_URL='http://conjur_server:80'
           export DECK_CONJUR_ACCOUNT='myConjurAccount'
           export DECK_CONJUR_LOGIN='host/BotApp/myDemoApp'
           export DECK_CONJUR_API_KEY='YOUR-API-KEY'
           ```
           You can find your API key listed under `myConjurAccount:host:BotApp/myDemoApp` in the `my_app_data` file.

      icon_url: /assets/icons/code.svg

cleanup:
  inline:
    - title: Clean up CyberArk Conjur
      content: |
        To clean up Conjur, delete the `conjur-quickstart` Docker container.
      icon_url: /assets/icons/code.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: How do I rotate my secrets in CyberArk Conjur and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in CyberArk Conjur by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.
  - q: How are CyberArk Conjur secrets referenced by {{site.base_gateway}}?
    a: |
        Because Conjur secrets are organized under policies, when referencing secrets defined in a non-root policy, you must encode the `/` in the secret reference. For example: `{vault://conjur-vault/BotApp%2FsecretVar}` is correct, `{vault://conjur-vault/BotApp/secretVar}` is incorrect.
  - q: Can users and hosts be used to authenticate Conjur Vaults?
    a: |
        Yes. If you were authenticating the `Dave` user, you'd configure `"login": "Dave@BotApp"` along with the API key for `Dave`. If you were authenticating the host, you'd use `"login": "host/BotApp/myDemoApp"` along with the `host` API key.

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
---

## Configure Conjur and {{site.base_gateway}} Docker networks

Because you are using Docker for both Conjur and {{site.base_gateway}} in this tutorial, you must configure the containers to use the same Docker network. This allows them to communicate with each other:

```sh
docker network connect conjur-net kong-quickstart-gateway
docker network connect conjur-net conjur_server
```

## Create a Vault entity for HashiCorp Vault 

Using decK, create a [Vault](/gateway/entities/vault/) entity with the required parameters for CyberArk Conjur:

{% entity_examples %}
entities:
  vaults:
    - name: conjur
      description: Storing secrets in Conjur Vault
      prefix: conjur-vault
      config:
        endpoint_url: ${endpoint_url}
        account: ${account}
        login: ${login}
        auth_method: api_key
        api_key: ${api_key}
variables:
  endpoint_url:
    value: $CONJUR_ENDPOINT_URL
  account:
    value: $CONJUR_ACCOUNT
  login:
    value: $CONJUR_LOGIN
  api_key:
    value: $CONJUR_API_KEY
{% endentity_examples %}

## Validate

To validate that the secret was stored correctly in Conjur, you can call a secret from your vault using the `kong vault get` command within the Data Plane container. 

{% validation vault-secret %}
secret: '{vault://conjur-vault/BotApp%2FsecretVar}'
value: 'your-secret'
{% endvalidation %}

If the Vault was configured correctly, this command should return the value of the secret. You can use `{vault://my-conjur/BotApp%2FsecretVar}` to reference the secret in any referenceable field.