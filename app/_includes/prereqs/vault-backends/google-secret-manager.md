To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must configure the following:

1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
1. On the [Secret Manager page](https://console.cloud.google.com/security/secret-manager), create a secret called `test-secret` with the following JSON content:
    ```json
    {
    "key": "example-key"
    }
    ```
1. Credentials/service account key: https://cloud.google.com/iam/docs/keys-create-delete#creating 