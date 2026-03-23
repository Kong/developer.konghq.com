---
title: Configure CyberArk Secrets Manager (Conjur) as a vault backend
permalink: /how-to/configure-cyberark-as-a-vault-backend/
content_type: how_to
description: "Learn how to reference CyberArk Secrets Manager secrets from {{site.base_gateway}}."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configuration parameters for CyberArk Secrets Manager vaults
    url: /gateway/entities/vault/?tab=conjur#vault-provider-specific-configuration-parameters
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
  - CyberArk Secrets Manager
tldr:
    q: How can I access CyberArk Secrets Manager secrets in {{site.base_gateway}}? 
    a: |
      Configure a Vault entity with `config.auth_method: api_key`, your CyberArk Secrets Manager endpoint URL (`config.endpoint_url`), account name (`config.account`), login (`config.login`), and API key (`config.api_key`). Reference the secret like `{vault://conjur-vault/BotApp%2FsecretVar}`, assuming your Vault prefix is `conjur-vault` and your secret was stored as `BotApp/secretVar`.

tools:
    - deck

prereqs:
  inline: 
    - title: CyberArk Secrets Manager
      content: |
        To run this tutorial, you'll need CyberArk Secrets Manager running with a secret stored.  
        
        If you don't already have CyberArk Secrets Manager, you can follow the Docker quickstart guide to [setup an OSS environment](https://www.conjur.org/get-started/quick-start/oss-environment/), [define a policy](https://www.conjur.org/get-started/quick-start/define-policy/), and [store a secret](https://www.conjur.org/get-started/quick-start/store-secret/). 

        {:.warning}
        > If you're running CyberArk Secrets Manager in Docker, change the proxy ports in `docker-compose.yml` to `"9443:443"`. Make sure the {{site.base_gateway}} and CyberArk Secrets Manager containers are using the same Docker network. If they aren't, you can run `docker network connect kong-quickstart-net conjur_server` to connect the CyberArk Secrets Manager compose stack to the {{site.base_gateway}} quickstart network.
        
        Export the CyberArk Secrets Manager environment variables:
        {% env_variables %}
        DECK_CONJUR_ENDPOINT_URL: 'http://conjur_server:80'
        DECK_CONJUR_ACCOUNT: 'myConjurAccount'
        DECK_CONJUR_LOGIN: 'host/BotApp/myDemoApp'
        DECK_CONJUR_API_KEY: 'YOUR-API-KEY'
        {% endenv_variables%}
        These environment variables use values from the CyberArk Secrets Manager Docker quickstart. If you are running CyberArk Secrets Manager in a different environment, modify them as needed.

        You can find your API key listed under `myConjurAccount:host:BotApp/myDemoApp` in the `my_app_data` file.

      icon_url: /assets/icons/cyberark.svg

cleanup:
  inline:
    - title: Clean up CyberArk Secrets Manager
      content: |
        If you're using the CyberArk Secrets Manager Docker quickstart, you can clean up CyberArk Secrets Manager by deleting the `conjur-quickstart` Docker compose stack.
      icon_url: /assets/icons/cyberark.svg
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: How do I rotate my secrets in CyberArk Secrets Manager and how does {{site.base_gateway}} pick up the new secret values?
    a: You can rotate your secret in CyberArk Secrets Manager by creating a new secret version with the updated value. You'll also want to configure the `ttl` settings in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} pulls the rotated secret periodically.
  - q: How are CyberArk Secrets Manager secrets referenced by {{site.base_gateway}}?
    a: |
        Because CyberArk Secrets Manager secrets are organized under policies, when referencing secrets defined in a non-root policy, you must encode the `/` in the secret reference. For example: `{vault://conjur-vault/BotApp%2FsecretVar}` is correct, `{vault://conjur-vault/BotApp/secretVar}` is incorrect.
  - q: Can users and hosts be used to authenticate CyberArk Secrets Manager Vaults?
    a: |
        Yes. If you were authenticating the `Dave` user, you'd configure `"login": "Dave@BotApp"` along with the API key for `Dave`. If you were authenticating the host, you'd use `"login": "host/BotApp/myDemoApp"` along with the `host` API key.
  - q: |
      {% include /gateway/vaults-format-faq.md type='question' %}
    a: |
      {% include /gateway/vaults-format-faq.md type='answer' %}

next_steps:
  - text: Review the Vaults entity
    url: /gateway/entities/vault/
  - text: What can be stored as a secret?
    url: /gateway/entities/vault/#what-can-be-stored-as-a-secret   

automated_tests: false
---

## Create a Vault entity for CyberArk Secrets Manager Vault 

Using decK, create a [Vault](/gateway/entities/vault/) entity with the required parameters for CyberArk Secrets Manager:

<!--vale off-->
{% entity_examples %}
entities:
  vaults:
    - name: conjur
      description: Storing secrets in CyberArk Secrets Manager Vault
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

To validate that the secret was stored correctly in CyberArk Secrets Manager, you can call a secret from your vault using the `kong vault get` command within the Data Plane container: 

{% validation vault-secret %}
secret: '{vault://conjur-vault/BotApp%2FsecretVar}'
value: 'your-secret'
{% endvalidation %}

This assumes your secret was stored in `BotApp/secretVar` in CyberArk Secrets Manager.

If the Vault was configured correctly, this command should return the value of the secret. You can use `{vault://my-conjur/BotApp%2FsecretVar}` to reference the secret in any referenceable field.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret). 