Before you begin, you must get the Gemini API key from Google Cloud:

1. Go to the [Google Cloud Console](https://console.cloud.google.com/).
2. Select or create a project.
3. Enable the **Generative Language API**:
    - Navigate to **APIs & Services > Library**.
    - Search for "Generative Language API".
    - Click **Enable**.
4. Create an API key:
    - Navigate to **APIs & Services > Credentials**.
    - Click **Create Credentials > API Key**.
    - Copy the generated API key.


Export the API key as an environment variable:
```sh
export DECK_GEMINI_API_KEY="<your_gemini_api_key>"
```