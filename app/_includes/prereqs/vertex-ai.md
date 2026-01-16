Before you begin, you must get the following credentials from Google Cloud:

- **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
- **Project ID**: Your Google Cloud project identifier
- **Location ID**: Your Google Cloud project location identifier
- **API Endpoint**: The global Vertex AI API endpoint `https://aiplatform.googleapis.com`

After creating the key, convert the contents of `modelarmor-admin-key.json` into a **single-line JSON string**.
Escape all necessary characters. Quotes (`"`) become `\"` and newlines become `\n`. The result must be a valid one-line JSON string.

Then export your credentials as environment variables:

```sh
export DECK_GCP_SERVICE_ACCOUNT_JSON="<single-line-escaped-json>"
export DECK_GCP_LOCATION_ID="<your_location_id>"
export DECK_GCP_API_ENDPOINT="<your_gcp_api_endpoint>"
export DECK_GCP_PROJECT_ID="<your-gcp-project-id>"
```

Set up GCP Application Default Credentials (ADC) with your quota project:

```sh
gcloud auth application-default set-quota-project <your_gcp_project_id>
```

Replace `<your_gcp_project_id>` with your actual project ID. This configures ADC to use your project for API quota and billing.