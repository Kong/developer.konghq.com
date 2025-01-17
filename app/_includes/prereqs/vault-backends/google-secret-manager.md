To add Secret Manager as a Vault backend to {{site.base_gateway}}, you must configure the following:

1. In the [Google Cloud console](https://console.cloud.google.com/), create a project and name it `test-gateway-vault`.
1. On the [Secret Manager page](https://console.cloud.google.com/security/secret-manager), create a secret called `test-secret` with the following JSON content:
    ```json
    {
    "key": "Bearer your-mistral-api-key"
    }
    ```
1. Create a service account key:
    1. In the [Google Cloud console](https://console.cloud.google.com/), click the `test-gateway-vault` project.
    1. Click the email address of the service account that you want to create a key for.
    1. From the Keys tab, create a new key from the add key menu and select JSON for the key type.
    1. Save the JSON file you downloaded.