1. Install Claude:

    ```sh
    curl -fsSL https://claude.ai/install.sh | bash
    ```

2. Create or edit the Claude settings file:

    ```sh
    mkdir -p ~/.claude
    nano ~/.claude/settings.json
    ```

    Put this exact content in the file:

    ```json
    {
        "apiKeyHelper": "~/.claude/anthropic_key.sh"
    }
    ```

3. Create the API key helper script:

    ```sh
    nano ~/.claude/anthropic_key.sh
    ```

    Inside, put a dummy API key:

    ```sh
    echo "x"
    ```

4. Make the script executable:

    ```sh
    chmod +x ~/.claude/anthropic_key.sh
    ```

5. Verify it works by running the script:

    ```sh
    ~/.claude/anthropic_key.sh
    ```

    You should see only your API key printed.