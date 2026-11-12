This guide uses [ngrok](https://ngrok.com/) to expose a local URL to the internet for local testing and development purposes.

1. [Install ngrok](https://ngrok.com/docs/getting-started/#step-1-install).
1. [Sign up for an ngrok account](https://dashboard.ngrok.com/) and find your [ngrok authtoken](https://dashboard.ngrok.com/get-started/your-authtoken).
1. Install the authtoken and connect the ngrok agent to your account:
   ```sh
   ngrok config add-authtoken <TOKEN>
   ```
1. Run ngrok:
   ```sh
   ngrok http 8080
   ```
1. Copy the **Forwarding** URL from the output.
1. In a new terminal window, export it as an environment variable:
   ```sh
   export NGROK_HOST='YOUR_FORWARDING_URL'
   ```
