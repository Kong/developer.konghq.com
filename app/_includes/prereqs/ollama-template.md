To complete this tutorial, make sure you have Ollama installed and running locally.

1. Visit the [Ollama download page](https://ollama.com/download) and download the installer for your operating system. Follow the installation instructions for your platform.

1. Start Ollama:
   ```sh
   ollama start
   ```

1. After installation, open a new terminal window and run the following command to run the `{{include.model}}` model:

   ```sh
   ollama run {{include.model}}
   ```

1. To set up the AI Proxy plugin, you'll need the upstream URL of your local Llama instance. In this example, we're running {{site.base_gateway}} locally in a Docker container, so the host is `host.docker.internal`:

   {% capture var %}
   {% env_variables %}
   DECK_OLLAMA_UPSTREAM_URL: 'http://host.docker.internal:11434{{include.path}}'
   {% endenv_variables %}
   {% endcapture %}

   {{ var | indent: 3 }}


   By default, Ollama runs at `localhost:11434`. You can verify this by running:

   ```sh
   lsof -i :11434
   ```

   - You should see output similar to:

     ```
     COMMAND   PID            USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
     ollama   23909  your_user_name   4u  IPv4 0x...            0t0  TCP localhost:11434 (LISTEN)
     ```
     {:.no-copy-code}

   - If Ollama is running on a different port, run:

     ```sh
     sudo lsof -iTCP -sTCP:LISTEN -n -P
     ```

   - Then look for the `ollama` process in the output and note the port number it’s listening on.
