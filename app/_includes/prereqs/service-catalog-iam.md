You need an [API in AWS API Gateway](https://docs.aws.amazon.com/apigateway/latest/developerguide/api-gateway-create-api-as-simple-proxy-for-http.html#api-gateway-create-api-as-simple-proxy-for-http-build) to ingest and a correctly configured IAM role for this integration. You can follow the setup instructions in the UI wizard when you add the AWS API Gateway instance or do the following:

{% navtabs "IAM-role" %}
{% navtab "AWS UI" %}
If you want to use the AWS console UI, follow the steps in Amazon's Creating an IAM role (console) documentation. Make sure to select Another AWS account and enter the Account ID (auto gen id here) and select Require external ID and enter the External ID (external id here). Navigate to the role in the console UI and copy the ARN to use in Konnect.
1. In the AWS console, navigate to the [**IAM**](https://console.aws.amazon.com/iam/) settings.
1. In the IAM sidebar, click **Roles**.
1. Click **Create role**.
1. For the Trusted entity type, select **AWS account**.
1. For the AWS account settings, select **Another AWS account**.
1. In the **Account ID** field, enter `144681897537`. 

   This is {{site.konnect_short_name}}'s account ID that is used for the IAM role principal.
1. Select the **Require external ID** checkbox.
1. In the **External ID** field, enter your {{site.konnect_short_name}} organization ID. You can find this by sending a [GET request to `/organizations/me`](/api/konnect/identity/#/operations/get-organizations-me) or in the {{site.konnect_short_name}} UI by navigating to your account in the top right and clicking the copy icon next to your organization name.
1. Click **Next**.
1. In the **Permission policy summary** field, enter the following:
```json
{
    "Version": "2012-10-17",
    "Statement": [
      { "Sid": "CloudWatchRead",
        "Effect": "Allow",
        "Action": ["cloudwatch:GetMetricData", "cloudwatch:GetMetricStatistics"],
        "Resource": "*"
      },
      { "Sid": "ApiGwRead",
        "Effect": "Allow",
        "Action": ["apigateway:GET"],
        "Resource": "*"
      }
    ]
  }
```
1. In the **Role name** field, enter `service-catalog-integration`. 
1. Click **Create role**.
{% endnavtab %}
{% navtab "AWS CLI" %}
1. Get your {{site.konnect_short_name}} org ID:
<!--vale off-->
{% konnect_api_request %}
url: /v3/organizations/me
status_code: 201
method: GET
region: global
{% endkonnect_api_request %}
<!--vale on-->
   This is used for the external ID in the AWS IAM role
1. Export your {{site.konnect_short_name}} org ID:
   ```sh
   export EXTERNAL_ID='YOUR-ORG-ID'
   ```
1. Export the {{site.konnect_short_name}} account ID:
   ```sh
   export ACCOUNT_ID='144681897537'
   ```
   This is {{site.konnect_short_name}}'s account ID that is used for the IAM role principal.
1. Configure and authenticate with AWS:
   ```sh
   aws configure
   ```
1. Create the Service Catalog IAM role:
```sh
aws iam create-role \
  --role-name service-catalog-integration \
  --assume-role-policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Effect": "Allow",
        "Action": "sts:AssumeRole",
        "Principal": { "AWS": "$ACCOUNT_ID" },
        "Condition": { "StringEquals": { "sts:ExternalId": "$EXTERNAL_ID" } }
      }
    ]
  }' \
  --description "Service Catalog integration role"
```
1. Copy and save your ARN from the output to add it to Konnect.
1. Configure the permissions policy on the role:
```sh
aws iam put-role-policy \
  --role-name service-catalog-integration \
  --policy-name ServiceCatalogRead \
  --policy-document '{
    "Version": "2012-10-17",
    "Statement": [
      { "Sid": "CloudWatchRead",
        "Effect": "Allow",
        "Action": ["cloudwatch:GetMetricData", "cloudwatch:GetMetricStatistics"],
        "Resource": "*"
      },
      { "Sid": "ApiGwRead",
        "Effect": "Allow",
        "Action": ["apigateway:GET"],
        "Resource": "*"
      }
    ]
  }'
```
{% endnavtab %}
{% endnavtabs %}