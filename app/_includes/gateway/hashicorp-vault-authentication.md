{{site.ee_product_name}} integrates with [HashiCorp Vault](https://www.vaultproject.io/) as a secrets backend
for storing and managing sensitive data such as certificates, API keys, and other credentials.
To securely connect to a HashiCorp Vault instance, {{site.ee_product_name}} supports multiple
authentication methods across generic, infrastructure, and cloud categories.

You can use both internal and external authentication methods depending on your environment. 
Internal authentication methods handle authentication entirely within HashiCorp Vault using credentials specific to Vault itself, such as a Vault token or an AppRole.
External authentication relies on an identity managed by an external provider or infrastructure platform, such as Kubernetes, AWS IAM, or Azure Microsoft Entra ID.
Authentication via a cloud provider uses JWT authentication. 
For details on which specific cloud IAM authentication mechanisms are supported, see the
[cloud provider support matrix](/gateway/cloud-provider-support-matrix/).

### Supported authentication methods

The following table describes which authentication methods are supported for HashiCorp Vault:

<!--vale off-->
{% table %}
columns:
  - title: Method
    key: method
  - title: Description
    key: description
  - title: Type
    key: type
rows:
  - method: "[Token](https://developer.hashicorp.com/vault/docs/auth/token)"
    description: Authenticate with a Vault token.
    type: Internal
  - method: "[TLS Certificate](https://developer.hashicorp.com/vault/docs/auth/cert)"
    description: Authenticate using SSL/TLS client certificates.
    type: Internal
  - method: "[AppRole](https://developer.hashicorp.com/vault/docs/auth/approle)"
    description: Authenticate with HashiCorp Vault-defined roles.
    type: Internal
  - method: |
      [JWT](https://developer.hashicorp.com/vault/docs/auth/jwt) {% new_in 3.13 %}
    description: Authenticate with a JWT from an OIDC provider.
    type: External
  - method: "[Kubernetes](https://developer.hashicorp.com/vault/docs/auth/kubernetes)"
    description: |
      Authenticate using a Kubernetes Service Account token. 
      This method is suitable when {{site.ee_product_name}} runs inside a Kubernetes cluster.
    type: External
  - method: |
      [AWS](https://developer.hashicorp.com/vault/docs/auth/aws) {% new_in 3.14 %}
    description: Authenticate using AWS IAM credentials, including the AWS EC2/IAM auth method supported by HashiCorp Vault.
    type: External
  - method: |
      [Azure](https://developer.hashicorp.com/vault/docs/auth/azure) {% new_in 3.14 %}
    description: Authenticate using Azure Microsoft Entra credentials.
    type: External
  - method: |
      [GCP](https://developer.hashicorp.com/vault/docs/auth/gcp) {% new_in 3.14 %}
    description: Authenticate using GCP IAM credentials.
    type: External
{% endtable %}
<!--vale on-->
