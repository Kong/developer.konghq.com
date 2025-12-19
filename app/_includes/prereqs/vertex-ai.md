Before you begin, you must get the following credentials from Google Cloud:

- **Service Account Key**: A JSON key file for a service account with Vertex AI permissions
- **Project ID**: Your Google Cloud project identifier
- **API Endpoint**: The global Vertex AI API endpoint `https://aiplatform.googleapis.com`

After creating the key, convert the contents of `modelarmor-admin-key.json` into a **single-line JSON string**.
Escape all necessary characters — quotes (`"`) and newlines (`\n`) — so that it becomes a valid one-line JSON string.
Then export your credentials as environment variables:

```bash
export DECK_GCP_SERVICE_ACCOUNT_JSON="<single-line-escaped-json>"
export DECK_GCP_SERVICE_ACCOUNT_JSON="your-service-account-json"
export DECK_GCP_PROJECT_ID="your-project-id"
```