To complete this tutorial, make sure you have Ollama installed and running locally.

1. Visit the [Ollama download page](https://ollama.com/download) and download the installer for your operating system. Follow the installation instructions for your platform.

1. Start Ollama:

   ```sh
   ollama start
   ```

1. After installation, open a new terminal window and run:

   ```sh
   ollama run llama2
   ```

   You can replace `llama2` with the model you want to run, such as `llama3`.

1. To set up the AI Proxy plugin, you'll need the upstream URL of your local Llama instance. 

{% env_variables %}
DECK_OLLAMA_UPSTREAM_URL: 'http://localhost:11434/api/chat'
section: prereqs
indent: 3
{% endenv_variables %}

   By default, Ollama runs at `localhost:11434`. You can verify this by running:

   ```sh
   lsof -i :11434
   ```

   - You should see output similar to:

     ```
     COMMAND   PID            USER   FD   TYPE             DEVICE SIZE/OFF NODE NAME
     ollama   23909  your_user_name   4u  IPv4 0x...            0t0  TCP localhost:11434 (LISTEN)
     ```

   - If Ollama is running on a different port, run:

     ```sh
     sudo lsof -iTCP -sTCP:LISTEN -n -P
     ```

   - Then look for the `ollama` process in the output and note the port number it’s listening on.

   {:.info}
   > If you're running {{site.base_gateway}} locally in a Docker container, export your upstream URL as `http://host.docker.internal:11434`
