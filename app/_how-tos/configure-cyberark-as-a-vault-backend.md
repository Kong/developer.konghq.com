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
        To run this tutorial, you'll need CyberArk Conjur running with a secret stored. 
        
        If you don't already have CyberArk Conjur, you can follow the Docker quickstart guide to [setup an OSS environment](https://www.conjur.org/get-started/quick-start/oss-environment/), [define a policy](https://www.conjur.org/get-started/quick-start/define-policy/), and [store a secret](https://www.conjur.org/get-started/quick-start/store-secret/). 

        {:.warning}
        > If you're running Conjur in Docker, change the proxy ports in `docker-compose.yml` to `"9443:443"`. The {{site.base_gateway}} and Conjur containers must also be using the same Docker network.
        
        Export the Conjur environment variables:
        ```sh
        export DECK_CONJUR_ENDPOINT_URL='http://conjur_server:80'
        export DECK_CONJUR_ACCOUNT='myConjurAccount'
        export DECK_CONJUR_LOGIN='host/BotApp/myDemoApp'
        export DECK_CONJUR_API_KEY='YOUR-API-KEY'
        ```
        These environment variables use values from the Conjur Docker quickstart. If you are running Conjur in a different environment, modify them as needed.

        You can find your API key listed under `myConjurAccount:host:BotApp/myDemoApp` in the `my_app_data` file.

      icon_url: /assets/icons/cyberark.svg

cleanup:
  inline:
    - title: Clean up CyberArk Conjur
      content: |
        If you're using the Conjur Docker quickstart, you can clean up Conjur by deleting the `conjur-quickstart` Docker container.
      icon_url: /assets/icons/cyberark.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
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

## Create a Vault entity for HashiCorp Vault 

Using decK, create a [Vault](/gateway/entities/vault/) entity with the required parameters for CyberArk Conjur:

<!--vale off-->
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
<!--vale on-->

## Validate

To validate that the secret was stored correctly in Conjur, you can call a secret from your vault using the `kong vault get` command within the Data Plane container: 

{% validation vault-secret %}
secret: '{vault://conjur-vault/BotApp%2FsecretVar}'
value: 'your-secret'
{% endvalidation %}

This assumes your secret was stored in `BotApp/secretVar` in Conjur.

If the Vault was configured correctly, this command should return the value of the secret. You can use `{vault://my-conjur/BotApp%2FsecretVar}` to reference the secret in any referenceable field.