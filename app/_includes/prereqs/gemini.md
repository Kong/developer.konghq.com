Before you begin, you must get the Gemini API key from Google Cloud:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select or create a project.
1. Navigate to **APIs & Services**.
1. In the APIs & Services sidebar, click **Library**.
1. Search for "Generative Language API".
1. Click **Gemini API**.
1. Click **Enable**.
1. Navigate back to **APIs & Services**.
1. In the APIs & Services sidebar, click**Credentials**.
1. From the **Create Credentials** dropdown menu, select **API Key**.
1. Copy the generated API key.


Export the API key as an environment variable:
```sh
export DECK_GEMINI_API_KEY="YOUR-GEMINI-API-KEY"
```