# developer.konghq.com
🦍 Source code for developer.konghq.com website.

## Run Locally

```bash
# Install prerequisites
make install-prerequisites

# Install dependencies
make install

# Create local .env file
# OAS Pages require VITE_PORTAL_API_URL to be set in your current environment, it should match the Kong supplied portal URL
cp .env.example .env

# Build the site and watch for changes 
make run
```

Once you see the `Server now ready on …` message, the docs site is available at [http://localhost:8888](http://localhost:8888).
