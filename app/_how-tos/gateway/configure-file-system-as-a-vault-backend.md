---
title: Configure the file system vault backend
permalink: /how-to/configure-file-system-as-a-vault-backend/
content_type: how_to
description: "Learn how to store and reference secrets from local files using the {{site.base_gateway}} file system vault."
products:
    - gateway

related_resources:
  - text: Secrets management
    url: /gateway/secrets-management/
  - text: Configuration parameters for the file system vault
    url: /gateway/entities/vault/?tab=file-system#vault-provider-specific-configuration-parameters

works_on:
    - on-prem
    - konnect

min_version:
  gateway: '3.15'

entities:
  - vault

tags:
    - secrets-management
    - security

search_aliases:
  - filesystem vault
  - file vault

tldr:
    q: How can I store and reference secrets from local files in {{site.base_gateway}}?
    a: |
      Create a directory for your secret files on the data plane, then configure a Vault entity with `name: fs` and `config.prefix` set to that directory path. 
      Reference secrets using `{vault://fs-vault/my-secret.txt}` for plain text files, or `{vault://fs-vault/creds.json/password}` to extract a specific key from a JSON file.

tools:
    - deck

prereqs:
  inline:
    - title: Secret files
      content: |
        Create a directory for your secrets on the {{site.base_gateway}} data plane and add at least one secret file.

        {% on_prem %}
        content: |
          For example, if using the quickstart Docker container:

          1. Create the directory:

             ```sh
             docker exec kong-quickstart-gateway mkdir -p /tmp/kong/secrets
             ```
          1. Create a test secret:

             ```
             docker exec kong-quickstart-gateway /bin/sh -c 'echo -n "my-secret-value" > /tmp/kong/secrets/my-secret.txt'
             ```
          1. Export the directory path as an environment variable for use with decK:
        {% endon_prem %}
        {% konnect %}
        content: |
          1. Since {{site.konnect_short_name}} data plane container names can vary, set your container name as an environment variable:

             ```sh
             export KONNECT_DP_CONTAINER='your-dp-container-name'
             ```
          1. Create the directory:

             ```sh
             docker exec $KONNECT_DP_CONTAINER mkdir -p /tmp/kong/secrets
             ```
          1. Create a test secret:

             ```
             docker exec $KONNECT_DP_CONTAINER /bin/sh -c 'echo -n "my-secret-value" > /tmp/kong/secrets/my-secret.txt'
             ```
          1. Export the directory path as an environment variable for use with decK:
        {% endkonnect %}
        
          {% env_variables %}
          DECK_FS_PREFIX: '/tmp/kong/secrets'
          {% endenv_variables %}

      icon_url: /assets/icons/gateway.svg

cleanup:
  inline:
    - title: Destroy the {{site.base_gateway}} container
      include_content: cleanup/products/gateway
      icon_url: /assets/icons/gateway.svg
    - title: Clean up Konnect environment
      include_content: cleanup/platform/konnect
      icon_url: /assets/icons/gateway.svg

faqs:
  - q: How do I rotate secrets in the file system vault, and how does {{site.base_gateway}} pick up the new values?
    a: |
      Update the file contents on disk. Configure the `ttl` setting in your {{site.base_gateway}} Vault entity so that {{site.base_gateway}} re-reads the file periodically.
  - q: Can the file system vault read secrets from subdirectories?
    a: |
      Yes. Reference the path relative to `config.prefix`. 
      For example, if your prefix is `/tmp/kong/secrets` and your secret is at `/tmp/kong/secrets/db/password.txt`, reference it as `{vault://fs-vault/db/password.txt}`.
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

## Create a Vault entity for the file system vault

Using decK, create a [Vault](/gateway/entities/vault/) entity that points to your secrets directory:

<!--vale off-->
{% entity_examples %}
entities:
  vaults:
    - name: fs
      prefix: fs-vault
      description: Storing secrets in local files
      config:
        prefix: ${fs_prefix}
variables:
  fs_prefix:
    value: $FS_PREFIX
{% endentity_examples %}
<!--vale on-->

## Validate

To validate that the Vault can read your secret, call it using the `kong vault get` command within the data plane container:

{% validation vault-secret %}
secret: '{vault://fs-vault/my-secret.txt}'
value: 'my-secret-value'
{% endvalidation %}

If the vault was configured correctly, this command returns the contents of the file.

You can now reference any file in the secrets directory from any referenceable field using `{vault://fs-vault/example-filename}`.

For JSON files, you can extract a specific key by appending it to the path. For example, if `/tmp/kong/secrets/creds.json` contains `{"username":"user","password":"pass"}`, reference individual values like `{vault://fs-vault/creds.json/password}`.

For more information about supported secret types, see [What can be stored as a secret](/gateway/entities/vault/#what-can-be-stored-as-a-secret).
